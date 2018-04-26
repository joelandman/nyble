
packages = $(shell find . -type d | grep -v "\.$" ) 

### The below are the mechanisms used to create build targets, completed 
### build targets, and clean up.
###
build    = $(addsuffix .build,$(packages))
complete = $(addsuffix .complete,$(packages))


all:   $(build) $(complete)

$(build):
	for p in $(packages) ; do \
	  touch $$p.build ;	  \
	done

%.complete: %.build     
	mkdir  ${TARGET}/root/x
	cd $* ; cp -v * ${TARGET}/root/x ; chroot  ${TARGET} /root/x/install
	#rm -rf ${TARGET}/root/x
	touch $*.complete

clean:  
	for p in $(packages) ; do \
	  rm -f $$p.build $$p.packages $$p.complete ; \
	done


