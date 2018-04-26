TARGET ?= /mnt/root

drivers = $(shell find . -type d | sed 's|^.||g' |sed 's|^/||g'  )


### The below are the mechanisms used to create build targets, completed 
### build targets, and clean up.
###
build    = $(addsuffix .build,$(drivers))
complete = $(addsuffix .complete,$(drivers))


all:   $(build) $(complete)

$(build):
	for p in $(drivers) ; do \
	  touch $$p.build ;	\
	done

%.complete: %.build     
	cd $* ; cp -vf * ${TARGET}/root;  chroot ${TARGET} /root/install
	rm -f ${TARGET}/root/install
	touch $*.complete

clean:  
	for p in $(drivers) ; do \
	  rm -f $$p.build $$p.drivers $$p.complete ; \
	done

###################################################
## debugging targets

print-%  : ; @echo $* = $($*)
# use as "make print-VARIABLE_NAME" to see variable name


