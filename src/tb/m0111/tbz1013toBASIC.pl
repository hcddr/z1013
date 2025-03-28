#!/usr/bin/perl
###########################################
# Konverter für Tiny-BASIC-Programme
# V. Pohlers, 16.11.2022 11:04:52
###########################################

#use strict;
use Data::Dumper;
use Getopt::Std;

my %options = ();
getopts( "b", \%options );


#$ARGV[0]||='d:\hobby3\z9001_tinybasic\programme\b.KNIFFEL.z80';
$ARGV[0]||='d:\hobby3\z9001_tinybasic\programme\HALLO.BAS';

die <<HELP unless @ARGV;
Aufruf: $0 [-b] tb-file
konvertiert Tiny-BASIC-Hex-Programme ins Text-Format
erkennt Z1013, ...
Option: -b erzeugt binäre BAS-Datei für Z9001
HELP

open IN, "<$ARGV[0]" or die "$ARGV[0] not found\n";
binmode IN;

# Daten komplett einlesen
my $data;
sysread IN, $data, 65000;
close IN;

my $start = 0;

#print Dumper($data);

# print ord(substr($data, 0x0d, 1)); # 211
# print ord(substr($data, 0x0e, 1)); # 211
# print ord(substr($data, 0x0f, 1)); # 211


sub byte($) {
	my $offs = shift;
	my $byte = ord(substr($data, $start + $offs, 1));
}

sub byteh($) {
	my $offs = shift;
	my $byte = ord(substr($data, $start + $offs, 1));
	sprintf('%.2X', $byte);
}

my $pgmstart = 0;
my $pgmende = length($data);

# Test auf Arbeitszellen und HEADER

if (byteh(0x0b) eq 'D4' && byteh(0x0c) eq '01' ) { 
	# Arbeitszellen vorhanden, Pgb beginnt auf 1152
	$pgmstart = 0x152; 
	$pgmende = byte(0x1f) + byte(0x20) * 256 - 0x1000;
} else { 
	# ggf mit HEADER-Vorblock?
	$start = 0x20;
}

if (byteh(0x0b) eq 'D4' && byteh(0x0c) eq '01' ) { 
	# Arbeitszellen vorhanden, Pgb beginnt auf 1152
	$pgmstart = 0x152; 
	$pgmende = byte(0x1f) + byte(0x20) * 256 - 0x1000;
} else {
	# kein Vorblock
	$start = 0;
}

print "headersize $start\n";
print "basic $pgmstart - $pgmende\n";

#print 'CURRNT ', byteh(0x0b), ' ', byteh(0x0c), "\n"; # D4 01
#print 'TXTUNF ', byteh(0x1f), ' ', byteh(0x20), "\n";


(my $file = "$ARGV[0]") =~ s/\.([^.]*)$//;
$file =~ s/b\.//;

print $file, "\n";

if ( defined $options{b} ) {
	open OUT, ">$file.BAS" or die;
	binmode OUT;
} else {
	open OUT, ">$file.basic" or die;
	binmode OUT;
} 

my $pos = $pgmstart;

#zeilennummer
do {
	#zeilennummer
	if ( defined $options{b} ) {
		# binär: einfach kopieren
		print OUT chr(byte($pos++));
		print OUT chr(byte($pos++));
	} else {
		# test: konvertieren zu dez
		print OUT byte($pos++) + byte($pos++) * 256, ' '; 
	}
	# zeileninhalt
	my $c;
	do { 	
		$c = byte($pos++);
		print OUT chr($c); 
	} until ($c == 0x0d or $pos >= $pgmende);
	
	#print "$pos >= $pgmende\n" ;
	
	# Endekennzeichen erreicht?
	if (byte($pos) == 0x1A) {$pos = $pgmende};
	
} until ($pos >= $pgmende);

if ( defined $options{b} ) {
	# Textende
	print OUT chr(0x1A);
}

close OUT;
