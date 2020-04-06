##################
#Plottin Genotype Rate in a Plate Map form
##################
### Written by CSJalbert



# This relies on files created by the GTscore pipline to create various summary plots. 
library(dplyr)
library(ggplot2)
library(tidyr)

#read sample genotype rates
#genotype rate per sample for single SNP data
sample_genotypeRate_singleSNP<-read.delim("sample_genotypeRate_singleSNP.txt",header=TRUE)

#create platemap for plotting
platemap_genotypeRate_singleSNP <- sample_genotypeRate_singleSNP %>%
  separate(col = sample, 
           into = c("project", "silly", "sample", "plate", "well"),
           sep = "_") %>% 
  mutate(Row=as.numeric(match(toupper(substr(well, 1, 1)), LETTERS)),
         Column=as.numeric(substr(well, 2, 5)))

#plot genotype rate for each plate seperately
#list of unique plates in project
plate_list <- sort(unique(platemap_genotypeRate_singleSNP$plate))
#for loop to make ggplots
plot_list = list()
for (i in seq_along(plate_list)) {
  #create plots
  p =  
    ggplot(subset(platemap_genotypeRate_singleSNP, platemap_genotypeRate_singleSNP$plate==plate_list[i]), 
           aes(x = Column, y = Row)) + 
    geom_point(aes(fill=GenotypeRate), color = "black", pch = 21, size=7) +
    coord_fixed(ratio=(13/12)/(9/8), xlim=c(0.5, 12.5), ylim=c(0.5, 8.5)) +
    scale_fill_gradientn(colours = c("#d7191c", "#fdae61", "#ffffbf", "#ffffbf", "#2c7bb6"), breaks = c(0, 0.5, 0.70, 0.80, 1), na.value = "black", limits = c(0,1)) +
    scale_y_reverse(breaks=seq(1, 8), labels=LETTERS[1:8]) +
    scale_x_continuous(breaks=seq(1, 12)) + 
    labs(title = paste("Plate Number:", plate_list[i])) +
    theme_bw()+
    theme(plot.title=element_text(hjust=0.5))
  plot_list[[i]] = p
}
#print plots
pdf("genotypeRateMapsByPlate.pdf")
for (i in seq_along(plot_list)) {
  print(plot_list[[i]])
}
dev.off()

