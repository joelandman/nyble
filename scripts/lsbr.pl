#!/usr/bin/perl

use strict;
use Data::Dumper;

my ($line,$kver,$kmajor,$kminor,$krel,@kv);
my ($bridge,@bridges,$net);
my ($brname,$brid,$brstp,$brif,@br,@if);

($kmajor,$kminor,$krel,@kv) = split(/\./,`uname -r`);
$kver=$kmajor+$kminor/100;
# grab kernel revision, because things change between releases ...

chomp(@bridges    = split(/\n/,`brctl show`));
map {shift @bridges} (1 .. 1);


foreach $bridge (@bridges) {
     $bridge =~ s/^\s+//g;
     $bridge =~ s/\s+$//g;
     $bridge =~ s/\s+/ /g;
     @br=split(/\s+/,$bridge);
     if ($#br == 3) {
	$brname = $br[0];
	$net->{$brname}->{id} 	= $br[1];
	$net->{$brname}->{stp} 	= $br[2];	
	push @{$net->{$brname}->{interfaces}},$br[3];
       }
      else
       {
	push @{$net->{$brname}->{interfaces}},$br[0];
       }
}

foreach $bridge (sort keys %{$net}) {
  @if = @{$net->{$bridge}->{interfaces}};
  printf "%s:\tinterfaces %s\n",
    $bridge,
    join(",",@if);
}
printf "\n\n";

