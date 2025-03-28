#!/usr/bin/perl
# vp 29.10.2020 erstellt

die <<HELP unless @ARGV;
Aufruf: bws adr
konvertiert BWS-Adresse des Z1013 ins Makro 

; bws(zeile 0..31, spalte 0..31) analog print_at
bws		function z,s,z*32+s+0EC00h

HELP

$adr = (oct '0x'.$ARGV[0]);

if ($adr >= 0xEC00) { $adr -= 0xEC00 }

$spalte = $adr % 32;
$zeile = int ($adr / 32);

printf "bws(%d,%d)\n",$zeile,$spalte;
