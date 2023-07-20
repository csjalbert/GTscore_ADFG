#!/bin/bash
if [ $# != 1 ]; then
	echo "usage: ~$ ADFG_rescore.sh project"
	exit
fi
echo "START TIME: $(date)
START DIR: $(pwd)
COMMAND: run_GTscore.sh $1


"

#set working variables
project=$1 ## directory of project

# begin scoring
cd ${project}_outputs # enter into project directory

rm ${project}_LOKI_input_split_*.csv # remove old loki split files

## Note, I am on a headless server but installed a lightweight version of X11 for plotting
# Start Xvfb with with display :1 and a screen resolution of 1024x768x16 in the background (&) 
Xvfb :1 -screen 0 1024x768x16 &
# Set the DISPLAY environment variable for R to use Xvfb
export DISPLAY=:1
# call genotypes and make new LOKI file + plots
Rscript ../ADFG_rescore_loci.R $1 # script to rescore 7 keeper loci
# Kill the Xvfb process after done with plots
killall Xvfb
## Done with graphical interface

# ditch bad loci from LOKI file 
grep -vFf ../loci2remove_*.txt ${project}_LOKI_input_all.csv > LOKI_input.csv # this needs to be project specific - SEAK, CI, YUK, etc remove their own
#grep -vFf ../loci2rescore.txt ${project}_LOKI_input_all.csv > LOKI_input.csv # all projects get these removed

# concatenate r script output (genotypes) with loki input
cat LOKI_input.csv LOKI_rescores.csv > LOKI_input_rescore.csv

# remove NTC entries from rescores
grep -v ",NTC," LOKI_input_rescore.csv > tmp; mv tmp LOKI_input_rescore.csv

# split LOKI inputs
	head -n1 LOKI_input_rescore.csv > LOKI_header
	sed -i 1d LOKI_input_rescore.csv
	sort -k4 -n LOKI_input_rescore.csv > tmp; mv tmp LOKI_input_rescore.csv # Sort by PlateID, so plate-wide issues can be handled in same 'split file'
	split -C 60MB -a 1 --additional-suffix ".csv" LOKI_input_rescore.csv LOKI_input_rescore_split_ # Split the loki file at 60MB, making sure to end on a whole line (-C)
	loki_inputs=( $(ls LOKI_input_rescore_split_*) )
	for input in "${loki_inputs[@]}"
	do
		cat LOKI_header $input > tmp
		mv tmp $input
	done
	
	echo "
        $(date): LOKI inputs for ${project} done.
	"	
	
	#clean up project_outputs dir
	cat LOKI_header LOKI_input_rescore.csv > tmp; mv tmp LOKI_input_all_rescore.csv
	rm LOKI_header LOKI_input_rescore.csv LOKI_input.csv
	rename "s/^/${project}_/" LOKI_input*.csv # rename LOKI files

	#move files to make clear these have not been edited
	mkdir not_rescored/ # make new directory for old raw outputs
	find . -maxdepth 1 -mindepth 1 -type f ! -name '*rescore*' -exec mv {} not_rescored \; # move all files except those that say rescore
	mv ${project}_scatterPlots/ not_rescored/
	mv lib/ not_rescored/ # move the lib/ directory to not_rescored/


