#!/usr/bin/perl

use strict; use warnings;
my %get_primer = ();
my %get_probes = (); #hash of probe information, 1d = locus, 2d=pos
my %get_SNP_alleles = ();  
##store locus information
open(PROBES, "<probes.txt") or die; <PROBES>; #open probes, discard header
while(<PROBES>) { #loop through probes, save info to hash
	$_ =~ s/\cM\cJ|\cM|\cJ/\n/g; #dos format catch
	my $line = $_; chomp($line);
	my @tabs = split(/\t/,$line);
	$tabs[0] = "$tabs[0]_$tabs[2]"; #single snp locus/allele files are locus_SNPpos so hacking here to match
	$get_primer{$tabs[0]} = $tabs[7];
	$get_probes{$tabs[0]}{$tabs[2]} = "$tabs[5]/$tabs[6]";
	$get_SNP_alleles{$tabs[0]}{$tabs[2]} = "$tabs[3]/$tabs[4]";
}
close PROBES;

my %get_haplo_alleles = ();
open(LOCUSTABLE, "<LocusTable_singleSNPs.txt") or die; <LOCUSTABLE>;
while(<LOCUSTABLE>){
	my $line = $_; chomp($line);
	my @tabs = split(/\t/,$line);
	my $allele_string = $tabs[2];
	$allele_string =~ s/,/\//g;
	$get_haplo_alleles{$tabs[0]} = $allele_string;
}
close LOCUSTABLE;

open(GENOS, "<polyGenResults_singleSNP.txt") or die; 
my $geno_sample_order = <GENOS>; chomp($geno_sample_order);
$geno_sample_order = "\t" . $geno_sample_order;
$geno_sample_order =~ s/\t/,/g;

open(COUNTS, "<AlleleReads_singleSNPs.txt") or die;
my $count_sample_order = <COUNTS>; chomp($count_sample_order);
$count_sample_order =~ s/\t/,/g;

open(OUT,">LOKI_input.csv");

my @get_sampleID = ();
if( $count_sample_order eq $geno_sample_order) {
	@get_sampleID = split(/,/,$geno_sample_order);
}
else{print "ERROR! inconsistent sample IDs between count and loci files"; die;}

print OUT "LAB_PROJECT_NAME,SILLY_CODE,SAMPLE_NUM,PLATE_ID,WELL_POS,LOCUS,POSITIONS,HAPLO_ALLELES,HAPLO_COUNTS,GENOTYPE,SNP_ALLELES,PROBES,FWD_PRIMER_SEQ\r\n";
while(<GENOS>) {
	my $line = $_; chomp($line);
	my @geno_tabs = split(/\t/,$line);
	$line = <COUNTS>; chomp($line);
	my @count_tabs = split(/\t/,$line);

	my $col_counter = 1;
	if ($geno_tabs[0] eq $count_tabs[0]) {
		my $locus = $geno_tabs[0];
		my $primer = $get_primer{$locus};
		my $haplo_alleles = $get_haplo_alleles{$locus};
		my $SNP_alleles = "";
		my $positions = "";
		my $probes = "";
		foreach my $pos (sort { $a<=>$b } keys %{$get_probes{$locus}}) {
			$positions = $positions . $pos . "|";
			$SNP_alleles = $SNP_alleles . $get_SNP_alleles{$locus}{$pos} . "|";
			$probes = $probes . $get_probes{$locus}{$pos} . "|";
			
		}	
		chop($positions); chop($SNP_alleles); chop($probes);
		
		my $sampleID = "";
		my $genotype = "";
		my $count = "";
		while($col_counter <= $#get_sampleID) {
			$sampleID = $get_sampleID[$col_counter];
			$sampleID =~ s/_/,/g;
			$count = $count_tabs[$col_counter];
			$count =~ s/,/\//g;
			$genotype = $geno_tabs[$col_counter];	
			$genotype =~ s/0/0,0/g;
			$genotype =~ s/,/\//g;
			$locus =~ s/_1$//g; #removing SNPpos that I added above

			print OUT "$sampleID,$locus,$positions,$haplo_alleles,$count,$genotype,$SNP_alleles,$probes,$primer\r\n";

			$col_counter++;
		}
	}
	else{print OUT "ERROR! inconsistent loci between count and geno files"; die;}
}
close GENOS; close COUNTS; close OUT;
