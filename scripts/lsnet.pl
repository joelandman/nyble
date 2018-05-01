#!/usr/bin/perl

use strict;
use Data::Dumper;
use Data::Utils;
use JSON::PP;

my ($f,$dev,@devices,$cmd,$rc,@bonds,$bond,$slave_net,@slaves,$bond_nic);
my ($path,$net,@ethtool,@ip,$ipv4,$ipv6,$line,$first,@proc);
my ($bm,@dev,$kver,$kmajor,$kminor,$krel,@kv);

exit if (!(-e '/sys/class/net/'));

($kmajor,$kminor,$krel,@kv) = split(/\./,`uname -r`);
$kver=$kmajor+$kminor/100;
# grab kernel revision, because things change between releases ...

chomp(@devices    = `ls /sys/class/net/ `);
foreach $dev (sort @devices) {
   next if ($dev =~ /bonding_masters/);
   $net->{$dev}->{state} =
          &get_sys_nic_data($dev,'operstate');
   $net->{$dev}->{carrier} =
               &get_sys_nic_data($dev,'carrier');
   $net->{$dev}->{mac} =
               &get_sys_nic_data($dev,'address');
   $net->{$dev}->{speed} =
               &get_sys_nic_data($dev,'speed');
   $net->{$dev}->{rx} =
	       &get_sys_nic_data($dev,'statistics/rx_bytes');
   $net->{$dev}->{tx} =
	       &get_sys_nic_data($dev,'statistics/tx_bytes');
	       
   chomp(@ip = split(/\n/,`ip addr show dev $dev`));
     
   foreach my $line (@ip) {
       $line =~ s/\s+$//;
       $line =~ s/^\s+//;
       if ($line =~ /\<(.*?)\>\s+(.*?)\s{0,}$/) {
	  my $flags = $1;
	  my $kvps  = $2;
	  my @kvp   = split(/\s/,$kvps);
	  map {$net->{$dev}->{flag}->{$_}=1;} (split(/\,/,$flags));
	  for (my $_i=0;$_i<=$#kvp;$_i+=2) {
	      my $_x = $kvp[$_i+1];
	      my $_y = $kvp[$_i];
	      $net->{$dev}->{flags}->{$_y}=$_x;
	  } 
	}       
      if ($line =~ /inet\s+(.*?)\s+brd\s+(.*?)\s+/) {
	push @{$net->{$dev}->{ipv4}},{addr => $1, mask => $2};
      }
      if ($line =~ /inet6\s+(.*?)\s+scope/) {
	push @{$net->{$dev}->{ipv6}},{addr => $1};
      }
    }
    if ($dev !~ /^lo$/) {
      chomp(@ethtool = split(/\n/,`ethtool -i $dev`));
      foreach my $line (@ethtool) {
	$line =~ s/\s+//g;
	my ($k,$v) = split(/:/,$line);
	$net->{$dev}->{$k}=$v
      }
      chomp(@ethtool = split(/\n/,`ethtool -P $dev`));
      foreach my $line (@ethtool) {
	$line =~ s/\s+//g;
	my ($k,$v) = split(/:/,$line,2);
	$net->{$dev}->{real_mac}=$v
      }
    }
}
     
printf "%8s [%8s] %4s: %-28s %5s %-9s %-9s\n",
	"DEVICE","MASTER","LINK","IP Address","MTU","TX (bytes)","RX (bytes)";
foreach $dev (sort keys %{$net}) {
  my $_s = ($net->{$dev}->{carrier} ? "up" : "down" );
  if (defined($net->{$dev}->{ipv4})) {
     foreach my $_ip (@{$net->{$dev}->{ipv4}}) {
  #         if [master] link  ip  mtu tx rx
	printf "%8s [%8s] %4s: %28s %5i % 9s % 9s\n",
	$dev,
	(defined($net->{$dev}->{flags}->{master}) ? $net->{$dev}->{flags}->{master} : ""),
	$_s,
	$_ip->{addr},
	(defined($net->{$dev}->{flags}->{mtu}) ? $net->{$dev}->{flags}->{mtu} : "0"),
	Data::Utils->bytes_to_size($net->{$dev}->{tx},{ digits => 3}),
	Data::Utils->bytes_to_size($net->{$dev}->{rx},{ digits => 3});
      }
  }
  else
  {
    printf "%8s [%8s] %4s: %28s %5i % 9s % 9s\n",
	$dev,
	(defined($net->{$dev}->{flags}->{master}) ? $net->{$dev}->{flags}->{master} : ""),
	$_s,
	"",
	(defined($net->{$dev}->{flags}->{mtu}) ? $net->{$dev}->{flags}->{mtu} : "0"),
	Data::Utils->bytes_to_size($net->{$dev}->{tx},{ digits => 3}),
	Data::Utils->bytes_to_size($net->{$dev}->{rx},{ digits => 3});
  }
  
  
foreach my $_ip (@{$net->{$dev}->{ipv6}}) {
   my $_m = (defined($net->{$dev}->{flags}->{master}) ? $net->{$dev}->{flags}->{master} : "");
    
  #         if [master] link  ip  mtu tx rx
    printf "%8s [%8s] %4s: %28s %5i % 9s % 9s\n",
    $dev,
    $_m,
    $_s,
    $_ip->{addr},
    (defined($net->{$dev}->{flags}->{mtu}) ? $net->{$dev}->{flags}->{mtu} : "0"),
    Data::Utils->bytes_to_size($net->{$dev}->{tx},{ digits => 3}),
    Data::Utils->bytes_to_size($net->{$dev}->{rx},{ digits => 3});
  }
}

sub get_sys_nic_data {
  my ($b,$f) = @_;
  my ($fh,$data,$buf,$len);
  my $path = sprintf '/sys/class/net/%s/%s',$b,$f;
  sysopen $fh,$path,'O_RDONLY' or return undef;
  $len = sysread $fh,$buf,4096 or return undef;
  close($fh);
  return "" if ($len == 0);
  $buf =~ s/\s+$//;
  return $buf;
}

sub format_mac {
  my ($mac,$fmt) = @_;

  if ($fmt eq "default") {
    return $mac;
    }
    elsif ($fmt eq "cisco") {
      my @octants = split(":",$mac);
      $mac="";
      for(my $i=0;$i<6;$i++) {
        $mac .= $octants[$i];
        $mac .= "." if (($i % 2) && ($i != 5));
      }
      return $mac;
    }
}
