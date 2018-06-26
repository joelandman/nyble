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

Nyble will build an image from the tools into a temporary scratch space.  This
build will then be snapshot into a tar.bz2 image using tar and pbzip2.  After that
the image will be incorporated into an initramfs, after adjusting the initramfs
configuration to include the tarball, and the elements required to unpack it.

This effectively limits the size of the tarball to 2GB, as cpio cannot handle
larger files at this moment.

### Build variables

Several important variables used for the build are
* DISTRO : which distribution you will use as the base of your image.  Current choices are debian9 and centos7

* TARGET : top level scratch directory for building the image.  Defaults to ```/mnt/root```.

* NYBLE_KERNEL : 0 or 1, with 0 indicating that the build should use the distro
provided default kernel.  This does mean you can build these images to be almost entirely based upon the distro itself, with minor modifications to some of the
startup scripts.  These modifications are necessary to run as a ramdisk booted OS.
The system will not likely function without them.

### Build configuration outside of variables

The Makefile includes distro specific configuration in ```OS/$DISTRO/{base,config}.conf``` .  The Makefile uses 1 target, ```finalizebase``` which should be the last target in ```OS/$DISTRO/config.conf```.  The ```OS/$DISTRO/base.conf``` portion of
the distro specific included Makefile should handle all of the base distro
package installation, and kernel installation.  The ```OS/$DISTRO/config.conf```
should handle all of the post installation configuration, additional driver,
package, and feature installation.

### Running builds

Note: for Centos7 builds, you will need to copy the contents of ```OS/centos7/rpm-gpg-keys``` to
```/etc/pki/rpm-gpg/```
	
```
	cp -v OS/centos7/rpm-gpg-keys/* /etc/pki/rpm-gpg/
```

or you will run into a yum bug, whereby it has keys installed in the image build TARGET, 
but the yum command cannot see them.  Working on a mechanism to resolve this.

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

```
  root=ram rootfstype=ramdisk udev.children-max=1 simplenet=1 verbose console=tty0
```

You can add options to this as needed.

### Boot Options

#### Networking
* ```net.ifnames=0|1``` setting this to 0 will disable renaming networks from
eth$N. Setting this to 1 will use _new_ naming scheme.  Default is 1.


* ```simplenet=0|1``` will remove/re-insert drivers for NICs, loop through all
     the network devices, bringing the NIC up, and then looking for a carrier.
     Those that have a carrier will be dhcp'ed.  Using ```simplenet=1``` is
     is the simplest way to bring up a node

* ```net_if=NET``` configure the NET device (must come before sub options
     below)

     * ```net_addr=IP/MASK``` set a particular IPv4 IP address/CIDR MASK to the
       NET address



* ```br_name=NAME``` create a linux bridge device named NAME (must come
  before the sub options below)

     * ```br_if=NET``` attach NET network device to the NAME bridge

     * ```br_addr=IP/MASK``` set a particular IPv4 IP address/CIDR MASK to the
       NAME bridge.  If not included, the bridge NAME will dhcp for an address

- For both ```net_if=NET``` and ```br_name=NAME```, the following suboptions exist

     * ```net_dns=IPDNS``` creates an ```nameserver IPDNS``` entry in ```/etc/resolv.conf```

     * ```net_gw=IPGW``` add a network gateway at address IPGW

* ```rootpw=PLAINTXT``` set a root password on boot.  Not secure, but usable
  in an emergency.  The image is immutable, but the instance of the image is not.
  So you can use this to start up an image instance with a new root password for
  running you own tests.  Since the instance image will not, by default, attach
  any specific durable storage, you can use this as a sandbox for testing.

* ```rootsize=X{G.M,K}``` set the tmpfs (if used) root disk size to X with units
  as indicated.

* ```disablettyS{0,1,2}=0|1``` enable (0) or disable any of the serial consoles (activated by default) from being used for logins.

* ```enablelldpd=0|1```  turn LLPD off (0) or on (1).  Off by default.

* ```zpoolimport=1```  For ZFS builds only, force a zpool import.

* ```ramdisktype=zram``` to use a zram (compressed ramdisk block device) rather
than the default tmpfs device.  This will create an ext4 file system atop the
```/dev/zram0``` device, and mount it as your root file system.

* ```ramdisksize=SIZE_IN_GB``` to set the ramdisk size to be SIZE_IN_GB number of
GB.  So if you wish to use a 5GB ramdisk, use ```ramdisksize=5```.  

Normal kernel boot parameters also apply to the image instance.  Due to udev
issues on startup, using ```udev.children-max=1``` is highly recommended.  You
may encounter race conditions if you use a number higher than 4.  You may turn
on basic deugging using ```debug```, or set console to physical terminal ```console=tty0```.

### Debugging

It is possible to break startup at a number of points before, during, and after
unpacking the rootfs into the ramdisk.

* ```break=preunpack``` will launch a shell before the system creates the ramdisk

* ```debug``` on the command line will also return the environment variables
prior to creating the ramdisk

* ```image=keep``` will prevent the startup procedure from deleting the snapshot
tarball.

* ```break=postunpack``` will launch a shell after the system creates the ramdisk
and unpacks the snapshot tarball.

Exiting these shells should continue startup operation.
