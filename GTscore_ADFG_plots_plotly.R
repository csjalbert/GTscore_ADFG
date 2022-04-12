##################
#Plotting Genotype Rate in a Plate Map form
# Written by CSJalbert
# This relies on files created by the GTscore pipline to create genotype rate summary plots. 
##################

if(!require("pacman")) install.packages("pacman");library(pacman) # install and load pacman
p_load(dplyr, tidyr, plotly, htmltools) # load or install+load required packages.


#read sample genotype rates
#genotype rate per sample for single SNP data
sample_genotypeRate_singleSNP<-read.delim("sample_genotypeRate_singleSNP.txt",header=TRUE)

#create platemap for plotting
platemap_genotypeRate_singleSNP <- sample_genotypeRate_singleSNP %>%
  tidyr::separate(col = sample, 
           into = c("project", "silly", "sample", "plate", "well"),
           sep = "_") %>% 
  tidyr::separate(col = well, 
           into = c("Row", "Column"), 
           sep = "(?<=[A-Z])(?=[0-9])", #split between upper case letter and number
           convert = TRUE) %>% 
  dplyr::mutate(Row = factor(Row, levels = paste(rev(LETTERS)))) # factorize it backwards to show rows properly (i.e., H - A)

#list of unique plates in project
plate_list <- sort(unique(platemap_genotypeRate_singleSNP$plate))


# plot genotype rate for each plate separately using an lapply to subset the dataset for each plate
plots <- lapply(seq_along(plate_list), function(i) {
  subset(platemap_genotypeRate_singleSNP, platemap_genotypeRate_singleSNP$plate==plate_list[i]) %>% 
    plotly::plot_ly(type = "scatter", # type of plot (scatter pot)
            mode = "markers", # just points, not lines and points
            x = ~Column, # x variable
            y = ~Row, # y variable
            marker = list(size = 20, # size of the points
                          cmax = 1, cmin = 0, #set color range - hard coded 0-1
                          color = ~GenotypeRate, # coloring according to genotype
                          colorscale = list(c(0, 0.5, 0.70, 0.80, 1), # set breaks for colors
                                            c("#d7191c", "#fdae61", "#ffffbf", "#ffffbf", "#2c7bb6")), # set color at each break
                          showscale = TRUE), # show the scale for the plot (i.e., legend)
            text = ~paste(silly, "_", sample), # this text will show up in the hover bubble
            # generate hover text by pasting in text call from above, adding a few line breaks with html coding (e.g.,italics, bold, breaks), genotype rate, and finally dropping all extra junk
            hovertemplate = ~paste(
              "<b>%{text}</b><br>",
              "GenotypeRate: ", round(GenotypeRate,2),
              "<extra></extra>"), # remove the "trace" from beside hover bubble - you'll know what I mean when you forget to add this
            width = 1500, # set plot width
            height = 1000) %>% # set plot height
    plotly::layout(xaxis = list(title = "Plate Column",
                        tickmode = "linear"), # title for axis and setting to fixed ticks
           yaxis = list(title = "Plate Row",
                        tickmode = "linear"),# title for axis and setting to fixed ticks
           title = ~paste("Plate Number:", plate_list[i]), # main plot title
           margin = list(l = 50, r = 50, b = 200, t = 50, pad = 20))# setting plot margins (space around plot axes) l = left; r = right; t = top; b = bottom
})

# generates an html doc with plots.
htmltools::save_html(html = htmltools::browsable(x = htmltools::tagList(plots)), file = paste0(unique(platemap_genotypeRate_singleSNP$project),"_genotypeRatePlots.html"))
