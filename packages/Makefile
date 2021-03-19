TARGET ?= /mnt/root

packages = $(shell find . -type d | sed 's|^.||g' |sed 's|^/||g'  )


### The below are the mechanisms used to create build targets, completed 
### build targets, and clean up.
###
build    = $(addsuffix .build,$(packages))
complete = $(addsuffix .complete,$(packages))


all:   prepare $(build) $(complete)
	echo "nameserver 1.1.1.1" >> ${TARGET}/etc/resolv.conf

prepare:
	cp -fv prepare.bash ${TARGET}/root
	chmod +x ${TARGET}/root/prepare.bash
	chroot ${TARGET}  /root/prepare.bash
	touch prepare

$(build): prepare
	for p in $(packages) ; do \
	  touch $$p.build ;	\
	done

%.complete: %.build
	mkdir -p  ${TARGET}/root/x 
	cp -vf $*/* ${TARGET}/root/x
	chroot ${TARGET} /root/x/install
	rm -rf ${TARGET}/root/x 
	touch $*.complete

clean:  
	for p in $(packages) ; do \
	  rm -f $$p.build $$p.packages $$p.complete ; \
	done
	rm -f prepare

###################################################
## debugging targets

print-%  : ; @echo $* = $($*)
# use as "make print-VARIABLE_NAME" to see variable name


