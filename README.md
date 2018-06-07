# About Nyble

(pronounced *nibble*)

Nyble solves the problem of configuration drift and bootable image divergence across fleets of physical/virtual machines, by creating immutable OS images.
These images can be network (PXE, SAN), USB, and local disk booted.  Nyble
instances, the booted version of a Nyble image, may be configured
programmatically upon boot, using any mechanism you prefer for configuration
management.

With a Nyble based OS image, you cannot get image divergence or configuration
drift across your fleet.  It solves this by creating a fixed bootable initramfs
artifact for a particular linux distribution.  The initramfs creation is driven
by the Makefile in this repo.  

Far more importantly, you should never have an errant driver or configuration stop a node from correctly booting.  You should always be able to come up to an operational state of an OS, and apply configuration 

## Theory of operation

Nyble sits atop the basic distro packaging mechanisms (apt, yum) and adds
specific configuration, tools, drivers, and packages that you may modify.  
One should be able to build an image from any distro as long as the
relevant target distro's tools are installed.

Several important variables used for the build are
* DISTRO : which distribution you will use as the base of your image.  Current choices are debian9 and centos7
* TARGET : top level scratch directory for building the image.  Defaults to ```/mnt/root```.
* NYBLE_KERNEL : 0 or 1, with 0 indicating that the build should use the distro
provided default kernel.  This does mean you can build these images to be almost entirely based upon the distro itself, with minor modifications to some of the
startup scripts.  These modifications are necessary to run as a ramdisk booted OS.
The system will not likely function without them.

The Makefile includes distro specific configuration in ```OS/$DISTRO/{base,config}.conf``` .  The Makefile uses 1 target, ```finalizebase``` which should be the last target in ```OS/$DISTRO/config.conf```.  The ```OS/$DISTRO/base.conf``` portion of
the distro specific included Makefile should handle all of the base distro
package installation, and kernel installation.  The ```OS/$DISTRO/config.conf```
should handle all of the post installation configuration, additional driver,
package, and feature installation.

You can execute up to a specific target, for example ```fb_final``` by running
  ```make fb_final```.  You can continue the image build process by running ```make```.

You can inspect any variable in the Makefile, by using ```make print-VARIABLE_NAME```

```
# make print-DISTRO
DISTRO = centos7

# make DISTRO=debian9 print-DISTRO
DISTRO = debian9

# make print-TARGET
TARGET = /mnt/root

# make TARGET=/outerspace  print-TARGET
TARGET = /outerspace

# make print-NYBLE_KERNEL
NYBLE_KERNEL = 1

# make NYBLE_KERNEL=0 print-NYBLE_KERNEL
NYBLE_KERNEL = 0
```


Upon successful completion of the build, you will have a kernel and initramfs located in ```${TARGET}/boot/``` that you may use for PXE booting.

Since git does not allow for large BLOB artifacts, you need to store them in
a different location which can be easily pulled during build.  This is


### Workflow

The Makefile includes distro specific configuration in OS/$DISTRO.  There are two
specific mechanisms for adding functionality, using the drivers or packages directory off of the main repository directory.

## Build a PXE bootable OS image

* building

You will need a machine with a fast network, and at least 64 GB RAM.  This
builds the image in a ramdisk, which you can copy out to permanent storage.
You can alter this behavior, by changing the TARGET= variable in the Makefile.


  ```
     git clone https://github.com/joelandman/nyble
     cd nyble
     # edit the kernel/kernel.conf ,
     # urls.conf ,
     # and OS/${DISTRO}/distro_urls.conf as needed to
     # point to local repos and kernel repos
     # Edit config/all.conf to adjust default features/functionality
     make [FEATURE_1=0|1] [FEATURE_2=0|1] ... [FEATURE_N=0|1]
  ```

rudimentary support for a bootable usb exists if you use the ```usb``` target.

If you wish to turn ZFS compilation on, add ```ZFS=1``` to the make command.

  ```make ZFS=1```


The bootable kernel and initramfs will be located in /mnt/root/boot.  Copy them
to the appropriate location for serving using iPXE and http on your machine.

## Using

  After configuring your system for iPXE boot, with the kernel and initramfs
located and available for service via http (much faster than tftp), make sure
you add the following boot options to the kernel line.

  ```root=ram rootfstype=ramdisk udev.children-max=1
     simplenet=1 verbose console=tty0```

If you want to turn off renaming networking to ```ensXfY...```, also add
```net.ifnames=0```



   simplenet=1 : will remove/re-insert drivers for NICs, loop through all
                 the network devices, bringing the NIC up, and then looking
                 for a carrier.  Those that have a carrier will be dhcp'ed

   net.ifnames=0 :  turn off renaming ethX to ensXfY

   net_if=NET   : configure the NET device (must come before sub options
                  below)
     net_addr=IP/MASK  : set a particular IPv4 IP address/CIDR MASK to the
                         NET address
     net_dns=IPDNS       : create an  ```nameserver IPDNS``` entry
                          in ```/etc/resolv.conf```
     net_gw=IPGW         : add a network gateway for NET at address IPGW

   br_name=NAME : create a linux bridge device named NAME (must come
                  before the sub options below)
     br_if=NET  : attach NET network device to the NAME bridge
     br_addr=IP/MASK : set a particular IPv4 IP address/CIDR MASK to the
                       NAME bridge.  If not included, the bridge NAME will
                       dhcp for a name
     net_dns=IPDNS       : create an  ```nameserver IPDNS``` entry
                          in ```/etc/resolv.conf```
     net_gw=IPGW         : add a network gateway for NAME at address IPGW

   rootpw=PLAINTXT : set a root password on boot.  Not secure, but usable in an
                     emergency
   rootsize=X{G.M,K} : set the tmpfs (if used) root disk size to X with units
                       as indicated.

   disablettyS{0,1,2}=1 : disable any of the serial consoles (activated
                          by default) from being used for logins.

   enablelldpd=1  :  turn on LLPD

   zpoolimport=1  :  force a zpool import
