#!/bin/bash -x
#
# chkconfig: 235 99 99
# description: nyble post boot config
### BEGIN INIT INFO
# Provides:          nyble
# Required-Start:    $local_fs $syslog
# Required-Stop:     $local_fs $syslog sendsigs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: nyble post boot configuration script
# Description:       nyble provides a post boot configuration mechanism
#
### END INIT INFO


#
# nyble provides post boot config
#
# description: Provide post boot config
# Author: joe.landman\@nlytiq.com
#
# Modified by:
# 2017/01/27 - Joe Landman <joe.landman\@nlytiq.com>
#	Initial setup
#
# /etc/init.d/nyble
#

RETVAL=0
#. /etc/init.d/functions
# See how we were called.
case "$1" in
    start)

	  echo -n "Starting post boot process configuration: "

	  # sanity check /proc /sys and /dev
	  if [ ! -d /proc ]; then
	     mkdir -p /proc
	     mount -t procfs procfs /proc
	  fi

	  if [ ! -d /sys ]; then
	     mkdir -p /sys
	     mount -t sysfs sysfs /sys
	  fi

	  if [ ! -d /dev ]; then
			 mkdir -p /dev
    	 mount -t devtmpfs devtmpfs /dev
	  fi

		# grab rootpw= if it exists
		if (grep -q rootpw= /proc/cmdline); then
	  	 rootpw=$(/opt/nyble/bin/get_cmdline_key.pl rootpw)
			 echo "root:$rootpw" | chpasswd
		fi

		# resize root ramdisk if rootsize= exists and root is on tmpfs
		if (grep -q rootsize= /proc/cmdline); then
			 rootfstype=$(mount | grep `df -h / | tail -1 | cut -d" " -f1` | head -1 | cut -f5 -d" ")
			 if [[ "$rootfstype" == "tmpfs" ]]; then
			  	 rootsize=$(/opt/nyble/bin/get_cmdline_key.pl rootsize)
					 mount -o remount,size=$rootsize /
			 fi
		fi

		# disablettyS0=1 turns off serial console on ttyS0
		if (grep -q disablettyS0=1 /proc/cmdline); then
			 systemctl disable serial-getty@ttyS0.service
			 systemctl stop serial-getty@ttyS0.service
		fi

		# disablettyS1=1 turns off serial console on ttyS1
		if (grep -q disablettyS1=1 /proc/cmdline); then
			 systemctl disable serial-getty@ttyS1.service
			 systemctl stop serial-getty@ttyS1.service
		fi

		# disablettyS2=1 turns off serial console on ttyS2
		if (grep -q disablettyS2=1 /proc/cmdline); then
		   systemctl disable serial-getty@ttyS2.service
			 systemctl stop serial-getty@ttyS2.service
		fi

		# enableIB=1 turns on IB modules
		if (grep -q enableIB=1 /proc/cmdline); then
				modprobe -v mlx4_ib
		    modprobe -v ib_ipoib
		    modprobe -v ib_umad
		    modprobe -v ib_ucm
		    modprobe -v ib_cm
		    modprobe -v ib_core
		    modprobe -v rdma_cm
		    modprobe -v rdma_ucm
		fi


	# use simplified networking if simplenet=1 is in boot commandline
	# basically bring up each ethernet (eth*) and then see whom has a
	# carrier.  DHCP those interfaces.  This breaks if portfast is not
	# enabled on your switches (it should be enabled unless there is a
	# very good reason to disable it)
		if (grep -q simplenet=1 /proc/cmdline); then

			# reset network state, loading specific drivers
			/etc/init.d/networking  stop
		  rmmod igb
		  rmmod ixgbe
		  rmmod i40e
		  rmmod cxgb4
		  rmmod mlx4_en
		  rmmod mlx5_core
			rmmod virtio-net
		  # blow away the insanity
		  rm -f /etc/udev/rules.d/70-persistent-net.rules
		  # /sigh
			sleep 2
			modprobe -v virtio-net
		  modprobe -v igb
		  modprobe -v e1000e
		  modprobe -v i40e
		  modprobe -v ixgbe
		  modprobe -v mlx4_en
		  modprobe -v mlx5_core

			/etc/init.d/networking start

			# bring interfaces up
			for net in $(ls /sys/class/net/ | grep eth) ; do
		      /sbin/ifconfig $net up
			done
		  sleep 10
			# sleep 10 seconds to make sure they establish link, then
			# probe for link.  dhclient on all interfaces with a link

			dhclient -x
			ports=""
			# currently hardwired for old ethX bits, fix for new naming scheme
			for net in $(ls /sys/class/net/ | grep eth); do
			 carrier="$( cat  /sys/class/net/$net/carrier )"
			 if [ $carrier -eq 1 ] ; then
			    ports="$ports $net"
			 fi
			done
			echo "ports= $ports"
			/usr/sbin/dhclient -v  $ports
		fi

		# grab rootpw= if it exists
		if (grep -q rootpw= /proc/cmdline); then
			 rootpw=$(/opt/nyble/bin/get_cmdline_key.pl rootpw)
			 echo "root:$rootpw" | chpasswd
		fi

		# grab sssdconfig= if it exists
		if (grep -q sssdconfig= /proc/cmdline); then
		   sssdconfig=$(/opt/nyble/bin/get_cmdline_key.pl ssdconfig)
		   mkdir -p /etc/sssd
		   cd /etc/sssd ; wget $sssdconfig -O sssd.config
		   chmod 700 /etc/sssd
		   chroot 600 /etc/sssd/sssd.config
		   systemctl enable sssd.service
		   systemctl start sssd.service
		fi

		# grab rootauthorizedkeys= if it exists
		if (grep -q rootauthorizedkeys= /proc/cmdline); then
		  rootauthorizedkeys=$(/opt/nyble/bin/get_cmdline_key.pl rootauthorizedkeys)
		  mkdir -p ~root/.ssh
		  cd ~root/.ssh ; wget $rootauthorizedkeys -O authorized_keys
		  chmod 600 ~root/.ssh/authorized_keys
		fi

		# grab runscript= if it exists
		if (grep -q runscript= /proc/cmdline); then
	     runscript=$(/opt/nyble/bin/get_cmdline_key.pl runscript)
	     cd /tmp ; wget $runscript -O runscript
	     chmod 700 runscript
	     ./runscript
		fi


		if (grep -q nfsserver= /proc/cmdline); then
			mkdir -p /var/lib/nfs/
			cd /tmp

			# grab the nfsserver option from the command line
			nfsserver=$(/opt/nyble/bin/get_cmdline_key.pl nfsserver)
			echo "nfsserver=${nfsserver}"
			mkdir -p /new_root
			mount -t nfs -o soft,rsize=65536,wsize=65536,retry=1,tcp,nolock,intr ${nfsserver} /new_root
			cd /new_root
			mkdir old_root
			pivot_root . old_root
			./bin/mount -n --move ./old_root/sys ./sys
			./bin/mount -n --move ./old_root/proc ./proc
			./bin/mount -n --move ./old_root/dev ./dev
			./bin/mount -n --move ./old_root/run ./run
			./bin/mount -n --move ./old_root/var ./var
			./bin/mount -n --move ./old_root/var/lib/nfs ./var/lib/nfs
			./bin/mount -n --move ./old_root/tmp ./tmp
			./bin/umount ./old_root/var/tmp
			./bin/umount ./old_root/var/lib/nfs
			./bin/umount ./old_root/data
			exec chroot . /bin/bash -c 'umount -l /old_root ; /sbin/init 3 ' <dev/console >dev/console 2>&1
		fi

	  # enablecloudinit=1 turns on cloud-init
	  if (grep -q enablecloudinit=1 /proc/cmdline); then
	      systemctl enable cloud-init
				systemctl start cloud-init
	  fi

	  # enablepuppet=1 turns on puppet
	  if (grep -q enablepuppet=1 /proc/cmdline); then
	      systemctl enable puppet
	      systemctl start puppet
	  fi
	      ;;

	stop)
	      ;;

	restart)
					echo -n "Restarting post boot process configuration: "
					/etc/init.d/nyble stop
					/etc/init.d/nyble start
	      ;;

	*)
	      echo "Usage: nyble {start|stop|restart}"
	      exit 1
esac
exit ${RETVAL}
