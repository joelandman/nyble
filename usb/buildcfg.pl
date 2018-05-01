#!/usr/bin/perl

use strict;


my ($line,$name,$msg,$opts,$first,$kernel,$initrd);

chomp($kernel = `ls  | grep vmlinuz`);
chomp($initrd = `ls  | grep initramfs`);


$first = 0;
while ($line = <>) {
  chomp($line);
  if ($line =~ /^(.*?)\,\"(.*?)\"\,\"(.*?)\"$/) {
     ($name,$msg,$opts) = ($1,$2,$3);
     #printf "name = %s, msg = %s, opts = %s\n",$name,$msg,$opts;
     if ($first == 0) {
     	printf "DEFAULT %s\n",$name;
	$first++;
     }
     printf "LABEL %s\n  SAY %s\n  KERNEL %s\n  APPEND initrd=%s %s\n\n",
	$name,$msg,$kernel,$initrd,$opts;
  }
}
