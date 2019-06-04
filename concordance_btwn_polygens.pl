#!/usr/bin/perl
use strict; use warnings;

my $polygen_qc = $ARGV[0];
my $polygen_proj = $ARGV[1];

open(QC,"<$polygen_qc") or die;
my $qcindline = <QC>; chomp($qcindline);
my @qcinds = split(/\t/,$qcindline);
my %qc_get_ind_from_col = ();
my %qc_get_col_from_ind = ();
my $col = 1;
foreach (@qcinds) {
	my $ind = $_;
	$qc_get_ind_from_col{$col} = $ind;
	$qc_get_col_from_ind{$ind} = $col;
	$col++;	
}

my %qc_lines = ();
while(<QC>) {
	my $line = $_; chomp($line);
	my @tabs = split(/\t/,$line);
	
	$qc_lines{$tabs[0]} = $line;
}
close QC;

open(PROJ,"<$polygen_proj") or die;
my $projindline = <PROJ>; chomp($projindline);
my @projinds = split(/\t/,$projindline);
my %proj_get_ind_from_col = ();
my %proj_get_col_from_ind = ();
$col = 1;
foreach (@projinds) {
        my $ind = $_;
        $proj_get_ind_from_col{$col} = $ind;
        $proj_get_col_from_ind{$ind} = $col;
        $col++;
}

my %proj_lines = ();
while(<PROJ>) {
        my $line = $_; chomp($line);
        my @tabs = split(/\t/,$line);

        $proj_lines{$tabs[0]} = $line;
}
close PROJ;

my %tests = ();
foreach my $qcind (keys %qc_get_col_from_ind) {
	my @qc_unders = split(/_/,$qcind);
	my $qc_SILLY_FISH = $qc_unders[0] . "_" . $qc_unders[1];
	foreach my $projind (keys %proj_get_col_from_ind) { 
		my @proj_unders = split(/_/,$projind);
		my $proj_SILLY_FISH = $proj_unders[0] . "_" . $proj_unders[1];
		
		if($qc_SILLY_FISH eq $proj_SILLY_FISH) {
			$tests{$projind} = "$proj_get_col_from_ind{$projind},$qc_get_col_from_ind{$qcind}";
		}
	}
}
print "ROW,PROJ_SILLY,PROJ_FISHID,PROJ_PLATE,PROJ_WELL,QC_SILLY,QC_FISHID,QC_PLATE,QC_WELL,LOCUS,PROJ_ALLELE_1,PROJ_ALLELE_2,QC_ALLELE_1,QC_ALLELE_2,CONCORDANCE,CONCORDANCE_TYPE\n";
my $row = 1;
foreach my $locus (keys %qc_lines) {
	if ($proj_lines{$locus} ne '') { 
		my @qc_tabs = split(/\t/,$qc_lines{$locus});
		my @proj_tabs = split(/\t/,$proj_lines{$locus});
		
		foreach my $test (keys %tests) {
			(my $proj_col, my $qc_col) = split(/,/,$tests{$test});
			$proj_tabs[$proj_col] =~ s/0/0,0/;
			$qc_tabs[$qc_col] =~ s/0/0,0/;
			
			my $proj_ind = $proj_get_ind_from_col{$proj_col};
			$proj_ind =~ s/_/,/g;

			my $qc_ind = $qc_get_ind_from_col{$qc_col};
                        $qc_ind =~ s/_/,/g;
			print "$row,$proj_ind,$qc_ind,$locus,$proj_tabs[$proj_col],$qc_tabs[$qc_col],";

			(my $proj_a1, my $proj_a2) = split(/,/,$proj_tabs[$proj_col]);
			(my $qc_a1, my $qc_a2) = split(/,/,$qc_tabs[$qc_col]);
			
			if ($proj_tabs[$proj_col] eq '0,0' && $qc_tabs[$qc_col] eq '0,0'){
				print "Agreement,Zero-Zero Agree\n";
			}
			elsif ($proj_tabs[$proj_col] eq '0,0') {
				print "Conflict,Project Zero\n";
			}
			elsif ($qc_tabs[$qc_col] eq '0,0') {
                                print "Conflict,QC Zero\n";
                        }
			elsif ($proj_tabs[$proj_col] eq $qc_tabs[$qc_col]) {
                                print "Agreement,Non-Zero Agree\n";
                        }
			elsif ($proj_a1 eq $proj_a2 && $qc_a1 eq $qc_a2) {
				print "Conflict,Homo-Homo\n";
			}
			elsif ($proj_a1 eq $proj_a2) {
				print "Conflict,ProjHomo-QCHet\n";
			}
			elsif ($qc_a1 eq $qc_a2) {
				print "Conflict,ProjHet-QCHomo\n";
			}
			else { 
				print "Conflict,Het-Het\n";
			}
			
			$row++;
		}
	}
}

