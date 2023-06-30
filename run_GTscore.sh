#!/bin/bash
#check if less than 3 inputs or more than 4, 4th is optional, hidden for read corrections
if [ $# -lt 3 ] || [ $# -gt 4 ]; then
	echo "usage: ~$ run_GTscore.sh bcl_dir barcodes probelist correctrescore[optional; true/false; default = false, normal scoring]"
	exit
fi 
echo "START TIME: $(date)
START DIR: $(pwd)
COMMAND: run_GTscore.sh $1 $2 $3 ${4:-false}


"

#set working variables
SECONDS=0
bcl_dir=$1 #directory containing Illumina Output format="181114_NB501665_0049_AHNCM3BGX7"
barcodes=$2 #SampleSheet
probes=$3 #Panel
correctrescore=${4:-false} #Check if the 'correctrescore' variable is provided (defaults to false if not provided). Used to determine which GTscore2LOKI.pl to use (single_snp or haplo based on if we used corrections).
date=$(date +%Y%m%d%H%M)
flowcell=$(echo $bcl_dir | cut -d"_" -f 4 | sed 's:/$::')
cd ${bcl_dir}
cd ../
proj_descript=$(pwd | rev | cut -d"/" -f 1 | rev | sed 's/[ _]//g')
analysis_dir="/mnt/anc_gen_cifs_research/Analysis/GTscore/${proj_descript}_${flowcell}_${date}"
dropoff_dir=$(pwd)

#setup analysis dir
mkdir ${analysis_dir}
mkdir ${analysis_dir}/GTscore/
rsync -av -f"- */" -f"+ *" /mnt/anc_gen_cifs_research/Software/GTscore_1.3/ ${analysis_dir}/GTscore/
cp $probes ${analysis_dir}
cp $barcodes ${analysis_dir}
mkdir ${analysis_dir}/fastq
mkdir ${analysis_dir}/logs


#bcl2fastq conversion
cp /mnt/anc_gen_cifs_research/Software/GTscore_1.3/dummySampleSheet.csv $bcl_dir/SampleSheet.csv
chmod 777 $bcl_dir/SampleSheet.csv
nohup bcl2fastq --use-bases-mask y150,i6,i6 --no-lane-splitting --runfolder-dir ${bcl_dir} --output-dir ${analysis_dir}/fastq
chmod 664 nohup.out
mv nohup.out ${analysis_dir}/logs/bcl2fastq.out
echo "
        $(date): bcl2fastq done.

"

#gunzip fastq
cd ${analysis_dir}/fastq
gunzip Undetermined_S0_R1_001.fastq.gz 
echo "        
	$(date): gunzip fastq done.

"

#Demultiplex fastq into split_seq
cd ../
grep -v "\#N/A" $barcodes | awk -F, 'BEGIN {OFS=","} {gsub(/_/,"",$1); print}' | sed 's/,NTC,/,NTC_0,/' | awk -F"," '{print $1"_"$2"_"$3"_"$6"\t"$5"\t"$8}' > barcodes.txt ##reformat barcodes and check for common problems
cp $probes probes.txt
mkdir split_seq/
cd split_seq/
perl ../GTscore/DemultiplexGTseq.pl -b ../barcodes.txt -s ../fastq/Undetermined_S0_R1_001.fastq 2>&1 | tee ${analysis_dir}/logs/demultiplexlog.out
echo "        
	$(date): barcode split done.

"

#for each project, loop through GTscore pipeline and create outputs
projects=( $(ls *fastq | grep -v discard | sed 's/_.*//g' | sort | uniq) )
for project in "${projects[@]}"
do
	#count allele reads for each locusxfish
	ls ${project}_*fastq | grep -v discarded > file_list.txt
	mkdir ../${project}_outputs
	perl ../GTscore/AmpliconReadCounter.pl -p ../probes.txt --files file_list.txt --printDiscarded --prefix ../${project}_outputs/ 2>&1 | tee ${analysis_dir}/logs/readcountlog.out
	echo "
        $(date): readcounting for $project done.
	
	"

	#call genotypes
	cd ../${project}_outputs
	Rscript ../GTscore/GTscore_pipeline.R 2>&1 | tee ${analysis_dir}/logs/GTscorelog.out
	echo "
	$(date): GTcalling for $project done.
	"
	
	#create ADFG inhouse plots
	Rscript ../GTscore/GTscore_ADFG_plots.R 2>&1 | tee ${analysis_dir}/logs/GTscoreplots.out
        echo "        
	$(date): Plots for $project done.
	"

        #create ADFG inhouse plots via plotly
	#keeping the old version until I am happy with plotly edition
        Rscript ../GTscore/GTscore_ADFG_plots_plotly.R 2>&1 | tee ${analysis_dir}/logs/GTscoreplotsplotly.out
        echo "
        $(date): Plots for $project done.
        "

	#create LOKI input
	cp ../probes.txt ./
	grep $project ../barcodes.txt > barcodes.txt
	## Check if optional read corrected rescore input is TRUE and use relevant scoring conversion
	if [ "$correctrescore" = false ]; then
		perl /mnt/anc_gen_cifs_research/Software/GTscore_1.3/GTscore2LOKI.pl 2>&1 | tee "${analysis_dir}/logs/LOKI.out"
		echo "
		$(date): Not rescored for LOKI (i.e., GTscore2LOKI.pl - uncorrected scoring method used), since correctedrescore was false.
		"
	else
		perl /mnt/anc_gen_cifs_research/Software/GTscore_1.3/GTscore2LOKI_singleSNPs.pl 2>&1 | tee "${analysis_dir}/logs/LOKI.out"
		echo "
		$(date): Rescored for LOKI (i.e., GTscore2LOKI_singleSNPs.pl - corrected scoring method used), since correctedrescore was true.
		"
	fi
	grep -v ",NTC," LOKI_input.csv > tmp; mv tmp LOKI_input.csv

	#split LOKI inputs
	head -n1 LOKI_input.csv > LOKI_header
	sed -i 1d LOKI_input.csv
	sort -k4 -n LOKI_input.csv > tmp; mv tmp LOKI_input.csv # Sort by PlateID, so plate-wide issues can be handled in same 'split file'
	#split -l 500000 -a 1 --additional-suffix ".csv" LOKI_input.csv LOKI_input_split_
	split -C 60MB -a 1 --additional-suffix ".csv" LOKI_input.csv LOKI_input_split_ #Split file at 60MB but end at whole line (-C)
	loki_inputs=( $(ls LOKI_input_split_*) )
	for input in "${loki_inputs[@]}"
	do
		cat LOKI_header $input > tmp
		mv tmp $input
	done
	
	echo "
        $(date): LOKI inputs for $project done.
	"	
	
	#clean up project_outputs dir
	cat LOKI_header LOKI_input.csv > tmp; mv tmp LOKI_input_all.csv
	rm LOKI_header LOKI_input.csv
	rename "s/^/${project}_/" * #rename all files to the project name
	rename "s/${project}_//g" ${project}_lib # remove project name from library directory for plotly genotype rate plot
	cd ../split_seq/
done

#copy outputs to Results_PICKUP  Dir
cd ../
mkdir /mnt/anc_gen_cifs_research/Results_PICKUP/${proj_descript}_${date}
cp -r *outputs /mnt/anc_gen_cifs_research/Results_PICKUP/${proj_descript}_${date}
chmod -R 777 /mnt/anc_gen_cifs_research/Results_PICKUP/${proj_descript}_${date}

echo "
END: $(date)"
duration=$SECONDS
echo "$(($duration/3600))h:$(($duration%3600/60))m:$(($duration%60))s"
#clean up and move Analysis Dir to Archive
sleep 1m
mv ${dropoff_dir}/${proj_descript}.screenlog ${analysis_dir}/logs/
mv ${dropoff_dir}/${proj_descript}.config ${analysis_dir}/logs/
mv ${dropoff_dir}/GTscore_WindowsRunner.ps1 ${analysis_dir}/GTscore/
mv ${dropoff_dir}/winRun_GTscore.bat ${analysis_dir}/GTscore/
mv ${analysis_dir} ${dropoff_dir}
mv ${dropoff_dir} /mnt/anc_gen_cifs_research/Archive/1_Pending/
