######## 
# Written by Chase Jalbert
# 10/14/2021
# Project: Chinook with IDFG299
#
# ADFG Genotyping calculations
# The script is run after GTscore.R and performs genotyping on known ill-behaved loci for the IDFG Chinook panel. 
# The loci have been identified as divergent duplicates and are part of the OG Templin set - we'd like to save them
# Specifically, the idea is to cut off depth, somewhere (e.g., >20 reads) then to genotype based on allelic ratios [a1/a2]
# Note, I am working with the singleSNP versions, not haplotypes, since that's what the plots output
# This needs to be done individually for each locus. Idea is to filter anything less than x # reads, 
# then score using windows. e.g., if(ratio = 0.1-0.2 then G,T,) elseif(ratio >0.2 but < 0.3 then T,T... etc. 
#
# There is a bash script that removes, other, bad loci from the loki file and adds these rescores to the final set of good loci
#
#
#
# Updates: This is a single scirpt, but should be a function that's incorporated into the GTscore_pipeline.R
#         Should be run before summaries, plotting, etc, so changes everywhere, not just hacked loki file
#         needs to cat loki inputs or something in the end
#
########

######### CAUTION ### 
# This script is run after the pipeline to help with modifying the LOKI input file. 
# At this point it is not incorporated into the pipeline. That means any files written by the pipeline, 
# that include the markers listed here, WILL be incorrect. In the future I need to incorporate so we can 'fix' scores during 
# the pipeline instead of simply editing the LOKI input file...
################

#args <- commandArgs(TRUE)
#print(args)
graphics.off() # reset graphics state 
library(tidyverse)

# Setup working directory - at this point this script is run from within the genotype folder
#genotypeDirectory="."
#setwd(genotypeDirectory)

# set a minimum number of acceptable reads
minreads = 20

# read in locus Table and AlleleRead files, generated from Pipeline
# read in locus Table and AlleleRead files, generated from Pipeline
singleSNP_locusTable <- readr::read_delim(file = dir( pattern = "_LocusTable_singleSNPs.txt"), col_names = TRUE, show_col_types = FALSE)
singleSNP_alleleReads <- readr::read_delim(file = dir( pattern = "_AlleleReads_singleSNPs.txt"), col_names = TRUE, show_col_types = FALSE) %>% dplyr::rename("Locus_ID" = "...1")

# List of known issue loci; loci in the loci2rescore file
# loci2rescore was created on the server, using bash
loci2fix <- dplyr::tibble( locus = c("ARNT_1","Ots_GH2_1","Ots_crRAD34397-33_1","Ots_TNF_1","Ots_u07-57.120_1","Ots_u1004-117_1","Ots_USMG5-67_1")) %>% dplyr::pull(locus)

# Subset locustable and allelereads for the loci we want to fix
sub_singleSNP_locusTable <- singleSNP_locusTable %>% dplyr::filter(Locus_ID %in% loci2fix)
sub_singleSNP_alleleReads <- singleSNP_alleleReads %>% dplyr::filter(Locus_ID %in% loci2fix)
#rownames(sub_singleSNP_alleleReads) <- sub_singleSNP_alleleReads[,1] 
#sub_singleSNP_alleleReads <- dplyr::select(sub_singleSNP_alleleReads, -loci)

# split alleleReads into allele1 count and allele2 count, calculate total reads, and ratio
alleleReads <- sub_singleSNP_alleleReads %>%
  #tibble::rownames_to_column("locus") %>% # grab locus names
  tidyr::pivot_longer(names_to =  "fish", values_to = "reads", -"Locus_ID") %>% # make long format
  dplyr::left_join(sub_singleSNP_locusTable %>% 
                     dplyr::select(-ploidy), by = "Locus_ID") %>% # joining locustable info (a1, a2)
  tidyr::separate(alleles, c("a1", "a2"), sep = ",", remove = TRUE) %>% # make cols for a1 and a2
  tidyr::separate(reads, c("allele1count", "allele2count"), sep = ",", remove = FALSE, convert = TRUE) %>% # create reads for allele1 and allele2
  dplyr::mutate(totalreads = allele1count + allele2count, # total reads
                ratios = allele1count / totalreads, # ratio a1 to total
                genotype = NA) # blank genotypes to fill in later

## SCORING ##
# Now score the markers, using windows, for each locus

combinedData <- alleleReads %>% 
  dplyr::mutate(genotype = case_when(totalreads < minreads ~ "0",  # must have more than 20 reads to get a genotype
                              Locus_ID == "ARNT_1" & ratios > 0.375 & ratios <= 0.63 ~ paste(a2, a2, sep = ","), # A2 homozygote
                              Locus_ID == "ARNT_1" & ratios > 0.68 & ratios <= 0.87 ~ paste(a1, a2, sep = ","), # Heterozygotes
                              Locus_ID == "ARNT_1" & ratios > 0.98 & ratios <= 1.01 ~ paste(a1, a1, sep = ","), # A1 homozygote
                              Locus_ID == "Ots_crRAD34397-33_1" & ratios >= 0 & ratios <= 0.25 ~ paste(a2, a2, sep = ","), # A2 homozygote
                              Locus_ID == "Ots_crRAD34397-33_1" & ratios > 0.49 & ratios <= 0.83 ~ paste(a1, a2, sep = ","), # Heterozygotes
                              Locus_ID == "Ots_crRAD34397-33_1" & ratios > 0.98 & ratios <= 1.01 ~ paste(a1, a1, sep = ","), # A1 homozygote
                              Locus_ID == "Ots_GH2_1" & ratios > 0.32 & ratios <= 0.52 ~ paste(a2, a2, sep = ","), # A2 homozygote
                              Locus_ID == "Ots_GH2_1" & ratios > 0.61 & ratios <= 0.83 ~ paste(a1, a2, sep = ","), # Heterozygotes
                              Locus_ID == "Ots_GH2_1" & ratios > 0.96 & ratios <= 1.01 ~ paste(a1, a1, sep = ","), # A1 homozygot
                              Locus_ID == "Ots_TNF_1" & ratios > 0.35 & ratios <= 0.50 ~ paste(a2, a2, sep = ","), # A2 homozygote
                              Locus_ID == "Ots_TNF_1" & ratios > 0.62 & ratios <= 0.80 ~ paste(a1, a2, sep = ","), # Heterozygotes
                              Locus_ID == "Ots_TNF_1" & ratios > 0.98 & ratios <= 1.01 ~ paste(a1, a1, sep = ","), # A1 homozygote
                              Locus_ID == "Ots_u07-57.120_1" & ratios >= 0 & ratios <= 0.15 ~ paste(a2, a2, sep = ","), # A2 homozygote
                              Locus_ID == "Ots_u07-57.120_1" & ratios > 0.35 & ratios <= 0.75 ~ paste(a1, a2, sep = ","), # Heterozygotes
                              Locus_ID == "Ots_u07-57.120_1" & ratios > 0.93 & ratios <= 1.01 ~ paste(a1, a1, sep = ","), # A1 homozygote
                              Locus_ID == "Ots_u1004-117_1" & ratios > 0.40 & ratios <= 0.57 ~ paste(a2, a2, sep = ","), # A2 homozygote
                              Locus_ID == "Ots_u1004-117_1" & ratios > 0.65 & ratios <= 0.85 ~ paste(a1, a2, sep = ","), # Heterozygotes
                              Locus_ID == "Ots_u1004-117_1" & ratios > 0.97 & ratios <= 1.01 ~ paste(a1, a1, sep = ","), # A1 homozygote
                              Locus_ID == "Ots_USMG5-67_1" & ratios >= 0 & ratios <= 0.12 ~ paste(a2, a2, sep = ","), # A2 homozygote
                              Locus_ID == "Ots_USMG5-67_1" & ratios > 0.25 & ratios <= 0.63 ~ paste(a1, a2, sep = ","), # Heterozygotes
                              Locus_ID == "Ots_USMG5-67_1" & ratios > 0.75 & ratios <= 1.01 ~ paste(a1, a1, sep = ","), # A1 homozygote
                              TRUE ~ "0")) # anything not falling within the specified windows recieves a zero


## EXPORT GENOTYPES ###
# I'll export the genotypes then can add them to the LOKI input file using bash. 

# convert genotypes into LOKI format and join in probe information then 
combinedData %>% dplyr::select(c(fish, LOCUS = Locus_ID, HAPLO_COUNTS = reads, GENOTYPE = genotype, a1, a2)) %>% # grab cols we need
  tidyr::separate(col = fish, into = c("LAB_PROJECT_NAME", "SILLY_CODE", "SAMPLE_NUM", "PLATE_ID", "WELL_POS"), sep = "_") %>% # split out fish names
  tidyr::unite("SNP_ALLELES", c("a1", "a2"), sep = "/", remove = TRUE) %>% # make possible alleles column
  tidyr::separate(col = LOCUS, into = "LOCUS", sep = "_1", extra = "drop")  %>%  # ditch the endings (_1), drop ignores the warning
  dplyr::left_join(readr::read_delim(file = dir( pattern = "_probes.txt"), col_names = TRUE, show_col_types = FALSE) %>% #read in probe file
                     select(c(LOCUS = `#locus`, POSITIONS = pos, p1, p2, FWD_PRIMER_SEQ = fp)) %>%  # grab columns we want
                     tidyr::unite("PROBES", c("p1", "p2"), sep = "/", remove = TRUE), by = "LOCUS") %>%  # make "probes" column
  dplyr::mutate(GENOTYPE = gsub(pattern = ",", replacement = "/", x = GENOTYPE), # convert to correct genotypes
                GENOTYPE = case_when(GENOTYPE == 0 ~ "0/0", # convert 0 calls to 0/0
                          TRUE ~ GENOTYPE),
                HAPLO_ALLELES = SNP_ALLELES, # no haplo so just copy these ones.. 
                HAPLO_COUNTS = gsub(pattern = ",", replacement = "/", x = HAPLO_COUNTS)) %>% # formatting
  dplyr::select(c(LAB_PROJECT_NAME, SILLY_CODE, SAMPLE_NUM, PLATE_ID, WELL_POS, LOCUS, POSITIONS, HAPLO_ALLELES, HAPLO_COUNTS, GENOTYPE, SNP_ALLELES, PROBES, FWD_PRIMER_SEQ)) %>% 
  readr::write_csv(file= "LOKI_rescores.csv")

## PLOTTING ###
# Generate allele plots for each of the loci

# function so we can call on it, once the final scripts are actually created. 
genoplot.f <-
  function(genodata, type = "ratio", savePlot = "N", saveDir = "") {
    # generate list of loci
    locusID <- as.character(sub_singleSNP_locusTable %>% pull(Locus_ID))
    
    #genodata$genotype <- factor(genodata$genotype) # factor classes for plotting
    
    for (marker in locusID) {
      # subset for each locus, factoring first, so plots are the same
      sub_genodata <- genodata %>% 
        dplyr::mutate(genotype = factor(genodata$genotype)) %>% 
        dplyr::filter(Locus_ID == marker)
      
      # calculate summary statistics
      genotypeRate <-
        round((length(sub_genodata$genotype) - sum(sub_genodata$genotype == "0")) / length(sub_genodata$genotype), digits = 2)
      
      averageReadDepth <- round(mean(sub_genodata$totalreads), digits = 2)
      
      # plot results, exclude ratios with NA from plot to prevent warnings
      summaryText = paste("average depth: ", averageReadDepth, "					", "genotype_rate: ", genotypeRate, sep = " ")
      
      if (type == "ratio") {
        genoPlot <- ggplot2::ggplot() +
          ggplot2::geom_histogram( data = sub_genodata, ggplot2::aes(x = ratios, color = genotype, fill = genotype),
                          binwidth = 0.01, 
                          alpha = 0.5,
                          na.rm = TRUE) +
          ggplot2::labs(title = marker,
               x = "Allele Ratio",
               y = "Frequency",
               subtitle = summaryText) +
          ggplot2::theme_bw() + 
          ggplot2::theme(plot.title = element_text(hjust = 0.5),
                plot.subtitle = element_text(hjust = 0.5)) +
          ggplot2::scale_x_continuous(breaks = seq(0, 1, 0.1), limits = c(-0.01, 1.01)) +
          ggplot2::scale_color_hue(drop = FALSE, breaks = levels(droplevels(sub_genodata$genotype)))
        
      } else if (type == "scatter_ratio") {
        genoPlot <- ggplot2::ggplot() +
          ggplot2::geom_point(data = sub_genodata, ggplot2::aes(x = ratios, y = totalreads, color = genotype), na.rm = TRUE) +
          ggplot2::labs(title = marker,
               x = "Allele Ratio",
               y = "Total Reads",
               subtitle = summaryText) +
          ggplot2::theme_bw() +
          ggplot2::theme(plot.title = element_text(hjust = 0.5),
                plot.subtitle = element_text(hjust = 0.5)) +
          ggplot2::scale_x_continuous(breaks = seq(0,1,0.05), limits = c(-0.01, 1.01)) + 
          ggplot2::scale_color_hue(drop = FALSE, breaks = levels(droplevels(sub_genodata$genotype)))
        
      } else if(type=="scatter"){
        genoPlot <- ggplot2::ggplot()+
          ggplot2::geom_point(data = sub_genodata, ggplot2::aes(x = allele1count, y = allele2count, color = genotype)) +
          ggplot2::xlim( range( sub_genodata$allele1count, sub_genodata$allele2count)) +
          ggplot2::ylim( range( sub_genodata$allele1count, sub_genodata$allele2count)) +
          ggplot2::labs( title = marker , x = "Allele 1 Reads", y = "Allele 2 Reads", subtitle = summaryText) + 
          ggplot2::coord_fixed( ratio = 1) +
          ggplot2::theme_bw() +
          ggplot2::theme(plot.title = element_text(hjust = 0.5),
                plot.subtitle = element_text(hjust = 0.5))+ 
          ggplot2::scale_color_hue(drop = FALSE, breaks = levels(droplevels(sub_genodata$genotype)))
      }
      
      # save plot if specified
      if (savePlot == "Y") {
        ggplot2::ggsave(filename = paste0(marker,"_",type, ".jpg"), plot = genoPlot, path = saveDir, device = "jpeg")
        
      } else{
        print(genoPlot)
      }
    }
  }

# call genotype plots function
# NOTE: not produced for multi-SNP haplotypes
dir.create("rescorePlots/")

# Ratio Plots  
genoplot.f(genodata = combinedData,
                  type='ratio', # options = ratio, scatter, scatter_ratio
                  savePlot="Y", 
                  saveDir="rescorePlots"
)

# Scatter Plots 
genoplot.f(genodata = combinedData,
           type='scatter', 
           savePlot="Y", 
           saveDir="rescorePlots"
)

# Scatter Ratio Plots  
genoplot.f(genodata = combinedData,
           type='scatter_ratio', 
           savePlot="Y", 
           saveDir="rescorePlots"
)
