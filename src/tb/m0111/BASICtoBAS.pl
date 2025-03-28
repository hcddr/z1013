#!/usr/bin/perl
###########################################
# Konverter für Tiny-BASIC-Programme
# V. Pohlers, 16.11.2022 11:04:52
###########################################

#use strict;
#use Data::Dumper;
#use Getopt::Std;


$ARGV[0]||='d:\hobby3\z9001_tinybasic\programme\MATHE-UEBUNG.basic';

die <<HELP unless @ARGV;
Aufruf: $0 [-b] tb-file
konvertiert Tiny-BASIC-Programme ins Hex-Format
erkennt Z1013, ...
HELP

open IN, "<$ARGV[0]" or die "$ARGV[0] not found\n";
$/ = "\x0d";			#Zeilenende

(my $file = "$ARGV[0]") =~ s/\.([^.]*)$//;
print $file, "\n";
open OUT, ">$file.BAS" or die;
binmode OUT;

while (<IN>) {
	chomp;
	next unless $_;		#Leerzeilen
	(my $linenumber, $line) = /^(\d+)\s+(.*)$/;
	#print "$linenumber: $line\n";
	print OUT pack("sA*", $linenumber, $line), "\x0d";
}

close IN;
print OUT "\x1A";
close OUT;

__END__

