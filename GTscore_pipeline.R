##################
#GENOTYPING
##################

#set working directory, change working directory as needed
#genotypeDirectory="K:/CODE/GTscore/ForDistribution"
#setwd(genotypeDirectory)
source("../GTscore/GTscore.R")

#SHOW GENOTYPING USING TEST DATASET FOR SPEED
singleSNP_locusTable<-read.delim("LocusTable_singleSNPs.txt",header=TRUE)
singleSNP_alleleReads<-read.delim("AlleleReads_singleSNPs.txt",header=TRUE,row.names=1)

haplotype_locusTable<-read.delim("LocusTable_haplotypes.txt",header=TRUE)
haplotype_alleleReads<-read.delim("AlleleReads_haplotypes.txt",header=TRUE,row.names=1)

#Correct reads if correctionFactors are supplied:
if("correctionFactors" %in% colnames(singleSNP_locusTable)){
	print("Using correction factors")
	singleSNP_alleleReads <- correctReads(locusTable = singleSNP_locusTable, readCounts = singleSNP_alleleReads)
} else {
	print("Not using correction factors")
}

#generate singleSNP genotypes
polyGenResults_singleSNP<-polyGen(singleSNP_locusTable,singleSNP_alleleReads)
#look at first five rows and columns
#polyGenResults_singleSNP[1:5,1:5]
#write results
write.table(polyGenResults_singleSNP,"polyGenResults_singleSNP.txt",quote=FALSE,sep="\t")

#Correct reads if correctionFactors are supplied:
#haplotype_alleleReads <- correctReads(locusTable = haplotype_locusTable, readCounts = haplotype_alleleReads)

#generate haplotype genotypes
polyGenResults_haplotypes<-polyGen(haplotype_locusTable,haplotype_alleleReads)
#look at first five rows and columns
#polyGenResults_haplotypes[1:5,1:5]
#write results to file
write.table(polyGenResults_haplotypes,"polyGenResults_haplotypes.txt",quote=FALSE,sep="\t")


#convert polyGen results to genepop data
#convert single SNP file, paralogs excluded by default
exportGenepop(polyGenResults_singleSNP,singleSNP_locusTable,filename="polyGenResults_singleSNP_genepop.txt")
#convert haplotype file, paralogs excluded by default
exportGenepop(polyGenResults_haplotypes,haplotype_locusTable,filename="polyGenResults_haplotype_genepop.txt")
##export files with paralogs
##convert single SNP file
#exportGenepop(polyGenResults_singleSNP,singleSNP_locusTable,filename="polyGenResults_singleSNP_genepop_withParalogs.txt",exportParalogs=TRUE)
##convert haplotype file
#exportGenepop(polyGenResults_haplotypes,haplotype_locusTable,filename="polyGenResults_haplotype_genepop_withParalogs.txt",exportParalogs=TRUE)

##convert to rubias format
##load sample data file
#sampleMetaData<-read.delim("sampleMetaData.txt",header=TRUE)
##export in rubias format
#exportRubias(polyGenResults_singleSNP,singleSNP_locusTable,sampleMetaData,filename="polyGenResults_singleSNP_rubias.txt")
#exportRubias(polyGenResults_haplotypes,haplotype_locusTable,sampleMetaData,filename="polyGenResults_haplotypes_rubias.txt")

##################
#DATA SUMMARIES
##################

#Sample Summaries
##load summary data containing total reads per sample
GTscore_individualSummary<-read.delim("GTscore_individualSummary.txt",header=TRUE,stringsAsFactors=FALSE)
#summarize single SNP results for samples
singleSNP_sampleSummary<-summarizeSamples(genotypes = polyGenResults_singleSNP,alleleReads = singleSNP_alleleReads)
write.table(singleSNP_sampleSummary,"singleSNP_sampleSummary.txt",quote=FALSE,sep="\t")
#combine AmpliconReadCounter individual summary data with GTscore sample summary
GTscore_individualSummary<-merge(GTscore_individualSummary,singleSNP_sampleSummary,by.x="Sample",by.y="sample")
GTscore_individualSummary <- GTscore_individualSummary %>% dplyr::mutate(NTC = grepl("NTC", Sample))  # define NTC

##summarize sample genotype rate
##calculate genotype rate per sample for single SNP data
sample_genotypeRate_singleSNP<-sampleGenoRate(polyGenResults_singleSNP)
write.table(sample_genotypeRate_singleSNP,"sample_genotypeRate_singleSNP.txt",quote=FALSE,sep="\t")

##calculate genotype rate per sample for haplotypes
sample_genotypeRate_haplotypes<-sampleGenoRate(polyGenResults_haplotypes)
sample_genotypeRate_haplotypes <- sample_genotypeRate_haplotypes %>% dplyr::mutate(NTC = grepl("NTC", sample))  # define NTC
write.table(sample_genotypeRate_haplotypes,"sample_genotypeRate_haplotypes.txt",quote=FALSE,sep="\t")

##Individual Summaries Plots
##This section produces summary plots for individuals.
pdf("SampleSummaryPlots.pdf")

#combine individual summary data with sample genotype rate
#GTscore_individualSummary<-merge(GTscore_individualSummary,sample_genotypeRate_singleSNP,by.x="Sample",by.y="sample")

#plot genotype rate for single SNP data
#ggplot()+geom_histogram(data=sample_genotypeRate_singleSNP,aes(x=GenotypeRate),binwidth=0.03)+
#  labs(title="Sample Genotype Rate Single SNP", x="Genotype Rate", y="Count")+
#  theme_bw()+theme(plot.title=element_text(hjust=0.5),plot.subtitle=element_text(hjust=0.5))


#plot histogram of genotype rate for single SNP data
ggplot()+geom_histogram(data=GTscore_individualSummary,aes(x=GenotypeRate,fill=NTC),binwidth=0.03)+xlim(-0.04,1.04)+
  labs(title="Sample Genotype Rate Single SNP", x="Genotype Rate", y="Count")+
  theme_bw()+scale_fill_manual(values=c("grey30","red"))+
  theme(plot.title=element_text(hjust=0.5),plot.subtitle=element_text(hjust=0.5),legend.position="inside",legend.location="plot",legend.justification.inside=c(0.02,0.98))

#plot genotype rate for haplotype data
ggplot()+geom_histogram(data=sample_genotypeRate_haplotypes,aes(x=GenotypeRate,fill=NTC),binwidth=0.03)+xlim(-0.04,1.04)+
  labs(title="Sample Genotype Rate Haplotype", x="Genotype Rate", y="Count")+
  theme_bw()+scale_fill_manual(values=c("grey30","red"))+
  theme(plot.title=element_text(hjust=0.5),plot.subtitle=element_text(hjust=0.5),legend.position="inside",legend.location="plot",legend.justification.inside=c(0.02,0.98))

#plot histogram of Heterozygosity
ggplot()+geom_histogram(data=GTscore_individualSummary,aes(x=Heterozygosity,fill=NTC),binwidth=0.03)+xlim(-0.04,1.04)+
  labs(title="Sample Heterozygosity", x="Heterozygosity", y="Count")+
  theme_bw()+scale_fill_manual(values=c("grey30","red"))+
  theme(plot.title=element_text(hjust=0.5),plot.subtitle=element_text(hjust=0.5),legend.position="inside",legend.location="plot",legend.justification.inside=c(0.98,0.98))

#plot genotype rate vs primer probe reads
#dashed line added at 90% genotype rate, this is not a strict threshold, just a goal to aim for
ggplot()+geom_point(data=GTscore_individualSummary,aes(x=Primer.Probe.Reads,y=GenotypeRate,colour=NTC))+
  labs(title="Genotype Rate vs Total Reads per Sample", x="Primer Probe Reads", y="Genotype Rate")+
  theme_bw()+scale_colour_manual(values=c("black","red"))+
  theme(plot.title=element_text(hjust=0.5),plot.subtitle=element_text(hjust=0.5),legend.position="inside",legend.location="plot",legend.justification.inside=c(0.98,0.02))+
  geom_hline(yintercept=0.9,lty="dashed")

#plot heterozygosity vs primer probe reads
ggplot()+geom_point(data=GTscore_individualSummary,aes(x=Primer.Probe.Reads,y=Heterozygosity,colour=NTC))+
  labs(title="Heterozygosity vs Total Reads per Sample", x="Primer Probe Reads", y="Heterozygosity")+
  theme_bw()+scale_colour_manual(values=c("black","red"))+
  theme(plot.title=element_text(hjust=0.5),plot.subtitle=element_text(hjust=0.5),legend.position="inside",legend.location="plot",legend.justification.inside=c(0.98,0.02))#+
  #geom_hline(yintercept=0.3, lty="dashed")

#plot heterozygosity vs genotype rate per sample
ggplot()+geom_point(data=GTscore_individualSummary,aes(x=GenotypeRate,y=Heterozygosity,colour=NTC))+
  labs(title="Heterozygosity vs Genotype Rate per Sample", x="Genotype Rate", y="Heterozygosity")+
  theme_bw()+scale_colour_manual(values=c("black","red"))+
  theme(plot.title=element_text(hjust=0.5),plot.subtitle=element_text(hjust=0.5),legend.position="inside",legend.location="plot",legend.justification.inside=c(0.02,0.98))

#plot heterozygosity vs contamination score per sample
ggplot()+geom_point(data=GTscore_individualSummary,aes(x=conScore,y=Heterozygosity,colour=NTC))+
  labs(title="Heterozygosity vs Contamination Score per Sample", x="Contamination Score", y="Heterozygosity")+
  theme_bw()+scale_colour_manual(values=c("black","red"))+
  theme(plot.title=element_text(hjust=0.5),plot.subtitle=element_text(hjust=0.5),legend.position="inside",legend.location="plot",legend.justification.inside=c(0.98,0.02))

dev.off()

#Locus Summaries 
#SummarizeData for Locus
##summarize single SNP results, remove NTCs
singleSNP_summary<-summarizeGTscore(singleSNP_alleleReads[,-grep(pattern="NTC",colnames(singleSNP_alleleReads))],singleSNP_locusTable,polyGenResults_singleSNP[,-grep(pattern="NTC",colnames(polyGenResults_singleSNP))])
#view results
head(singleSNP_summary)
#make AvgReadDepth 0 when N/A
singleSNP_summary <- singleSNP_summary %>% 
  dplyr::mutate(AvgReadDepth = dplyr::case_when(is.na(AvgReadDepth) & GenotypeRate == 0 ~ 0,
                                                TRUE ~ AvgReadDepth))
#write results
write.table(singleSNP_summary,"singleSNP_summary.txt",quote=FALSE,sep="\t",row.names=FALSE)

##summarize haplotype results, remove NTCs
haplotype_summary<-summarizeGTscore(haplotype_alleleReads[,-grep(pattern="NTC",colnames(haplotype_alleleReads))],haplotype_locusTable,polyGenResults_haplotypes[,-grep(pattern="NTC",colnames(polyGenResults_haplotypes))])
#view results
head(haplotype_summary)
#make AvgReadDepth 0 when N/A
haplotype_summary <- haplotype_summary %>% 
  dplyr::mutate(AvgReadDepth = dplyr::case_when(is.na(AvgReadDepth) & GenotypeRate == 0 ~ 0,
                                                TRUE ~ AvgReadDepth))
#write results
write.table(haplotype_summary,"haplotype_summary.txt",quote=FALSE,sep="\t",row.names=FALSE)

# This section produces summary plots for loci.
#GENERATE PLOTS FOR SINGLE SNP RESULTS
#plot genotype rate
pdf("LocusSummaryPlots.pdf")
ggplot()+geom_histogram(data=singleSNP_summary,aes(x=GenotypeRate),binwidth=0.03)+xlim(-0.04,1.04)+
  labs(title="Locus Genotype Rate Single SNP", x="Genotype Rate", y="Count")+
  theme_bw()+theme(plot.title=element_text(hjust=0.5),plot.subtitle=element_text(hjust=0.5))

#plot average read depth for single SNP data
ggplot()+geom_histogram(data=singleSNP_summary,aes(x=AvgReadDepth),binwidth=20)+
  labs(title="Average Read Depth Single SNP", x="Average Read Depth", y="Count")+
  theme_bw()+theme(plot.title=element_text(hjust=0.5),plot.subtitle=element_text(hjust=0.5))

#plot genotype rate relative to average depth
ggplot()+geom_point(data=singleSNP_summary,aes(x=AvgReadDepth,y=GenotypeRate))+ylim(-0.01,1.01)+
  labs(title="Genotype Rate vs Average Depth Single SNP", x="Average Depth", y="Genotype Rate")+
  theme_bw()+theme(plot.title=element_text(hjust=0.5),plot.subtitle=element_text(hjust=0.5))

#plot distribution of minor allele frequency
ggplot()+geom_histogram(data=singleSNP_summary,aes(x=minAF))+
  labs(title="Minor Allele Frequency Single SNP", x="Minor Allele Frequency", y="Count")+
  theme_bw()+theme(plot.title=element_text(hjust=0.5),plot.subtitle=element_text(hjust=0.5))

#plot distribution of major allele frequency
ggplot()+geom_histogram(data=singleSNP_summary,aes(x=majAF))+
  labs(title="Major Allele Frequency Single SNP", x="Major Allele Frequency", y="Count")+
  theme_bw()+theme(plot.title=element_text(hjust=0.5),plot.subtitle=element_text(hjust=0.5))

#GENERATE PLOTS FOR HAPLOTYPE RESULTS
#plot genotype rate
ggplot()+geom_histogram(data=haplotype_summary,aes(x=GenotypeRate),binwidth=0.03)+xlim(-0.04,1.04)+
  labs(title="Locus Genotype Rate Haplotypes", x="Genotype Rate", y="Count")+
  theme_bw()+theme(plot.title=element_text(hjust=0.5),plot.subtitle=element_text(hjust=0.5))

#plot average read depth for single SNP data
ggplot()+geom_histogram(data=haplotype_summary,aes(x=AvgReadDepth),binwidth=20)+
  labs(title="Average Read Depth Haplotypes", x="Average Read Depth", y="Count")+
  theme_bw()+theme(plot.title=element_text(hjust=0.5),plot.subtitle=element_text(hjust=0.5))

#plot genotype rate relative to average depth
ggplot()+geom_point(data=haplotype_summary,aes(x=AvgReadDepth,y=GenotypeRate))+ylim(-0.01,1.01)+
  labs(title="Genotype Rate vs Average Depth Haplotypes", x="Average Depth", y="Genotype Rate")+
  theme_bw()+theme(plot.title=element_text(hjust=0.5),plot.subtitle=element_text(hjust=0.5))

#plot distribution of minor allele frequency
ggplot()+geom_histogram(data=haplotype_summary,aes(x=minAF))+
  labs(title="Minor Allele Frequency Haplotypes", x="Minor Allele Frequency", y="Count")+
  theme_bw()+theme(plot.title=element_text(hjust=0.5),plot.subtitle=element_text(hjust=0.5))

#plot distribution of major allele frequency
ggplot()+geom_histogram(data=haplotype_summary,aes(x=majAF))+
  labs(title="Major Allele Frequency Haplotypes", x="Major Allele Frequency", y="Count")+
  theme_bw()+theme(plot.title=element_text(hjust=0.5),plot.subtitle=element_text(hjust=0.5))

dev.off()


#Genotype Plots
#NOTE: not produced for multi-SNP haplotypes
#Allele Ratio Plots  
#plotGenotypes(singleSNP_locusTable, singleSNP_alleleReads, polyGenResults_singleSNP, type='ratio', savePlot="Y", saveDir="ratioPlots")
#Scatter Plots 
dir.create("scatterPlots")
plotGenotypes(singleSNP_locusTable, singleSNP_alleleReads, polyGenResults_singleSNP, type='scatter', savePlot="Y", saveDir="scatterPlots")


##plot MSA alignments
##load reference sequences in table format
#referenceSeqs<-read.delim("ampliconRefSeqs.txt", header=TRUE, stringsAsFactors=FALSE )
##load primer probe file
#primerProbes<-read.delim("PrimerProbeFile.txt", header=TRUE, stringsAsFactors=FALSE)
##primer aligned reads
#primerMatchedReads<-read.delim("matchedReads_primerAligned.txt", header=TRUE, stringsAsFactors=FALSE)
#alignMatchedSeqs(primerProbes=primerProbes,matchedReads=primerMatchedReads,minReads=20, maxAlignedSeqs=100,type="primer",saveDir="MSA_primerMatched")
##primer probe aligned reads
#primerProbeMatchedReads<-read.delim("matchedReads_primerProbeAligned.txt", header=TRUE, stringsAsFactors=FALSE)
#alignMatchedSeqs(referenceSeqs, primerProbes=primerProbes, matchedReads=primerProbeMatchedReads,minReads=20, maxAlignedSeqs=100,type="primerProbe",saveDir="MSA_primerProbeMatched")

##plot mismatches by position
##load results from seqMismatchPositions.pl
##primer matched sequences
#mismatchPositionData_primer<-read.delim("mismatchPositions_primer.txt", header=TRUE, stringsAsFactors=FALSE)
##primer probe matched sequences
#mismatchPositionData_primerProbe<-read.delim("mismatchPositions_primerProbe.txt", header=TRUE, stringsAsFactors=FALSE)

##generate plots of mismatches by position
##primer matched sequences
#summarizeMismatches(mismatchPositionData_primer,saveDir="mismatchPositionPlots_primer")
##primer probe matched sequences
#summarizeMismatches(mismatchPositionData_primerProbe,saveDir="mismatchPositionPlots_primerProbe")
