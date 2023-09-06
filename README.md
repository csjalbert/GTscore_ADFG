# GTscore_ADFG
*Note - This will be updated to include documentation for our usage, but in the meantime, review the readme that is linked below and the GTscoreDocumentation V1.3 document.*

This is ADF&Gs internal pipeline for GTseq utilizing McKinney's [GTscore](https://github.com/gjmckinney/GTscore) pipeline for genotyping. 

Here is the introduction from the original GTscore documnetation (I highly recommend reviewing the full document):


# Introduction (*from GTscoreDocumentaton V1.3*)
GTscore is an enhanced analysis pipeline for handling GT-seq data (Campbell et al. 2015).  It has been designed to process amplicon sequencing data in fastq format and can directly handle output from Stacks (Catchen et al. 2013). It runs either in a Windows or Unix environment. Enhancements beyond the original GT-seq_pipeline (see [Campbell et al. 2015](https://github.com/GTseq/GTseq-Pipeline)) include:

    - Determines genotypes for both multi-SNP haplotypes and single-SNP genotypes
    - Retains phase for multi-SNP haplotypes
    - Handles genotypes for loci with varying ploidy level
    - Provides detailed summaries and plots and optional diagnostics

Multi-SNP haplotypes or so-called microhaplotypes are becoming increasing important in forensics (Kidd & Speed 2015); they also have been shown to substantially increase accuracy of mixture and individual assignments analyses in non-model organisms (e.g., McKinney et al. 2017a; Baetscher et al. 2018).   

In addition, many eukaryotic genomes retain duplicates loci or paralogs. While these loci have historically been treated as a nuisance and commonly removed from NGS data by filtering (Dufresne 2016), recent analyses now allow highly accurate identification of these loci through pipelines such as HDplot (McKinney et al. 2017b). Duplicated loci are being increasingly incorporated into population genetic analyses (Waples et al. 2016; Limborg et al. 2017). Amplicon sequencing data derived from GT-seq pipelines is particularly powerful for determining genotypes of duplicated or higher ploidy loci because of the relatively high depths of coverage available (McKinney et al. 2018).

*GT-score* is capable of genotyping data both as single SNPs and as multi-SNP haplotypes; both analysis methods handle varying ploidy levels. There are main four steps to running GT-score:

    1. Demultiplex raw sequence data
    2. Count sequence reads for each locus
    3. Genotype samples based on read counts
    4. Produce data summaries and plots
    
Steps 1 and 2 are Perl scripts. Steps 3 and 4 are run through R and are partially based on the R scripts in PolyGen (McKinney et al. 2018).

An additional fifth diagnostic step is included to assist in identifying patterns of sequence variation for loci; diagnostics require both R and Perl scripts.

      5.  Optional diagnostics



