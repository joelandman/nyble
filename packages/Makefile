
packages = $(shell find . -type d | grep -v "\.$") 

### The below are the mechanisms used to create build targets, completed 
### build targets, and clean up.
###
build    = $(addsuffix .build,$(packages))
complete = $(addsuffix .complete,$(packages))


all:   $(build) $(complete)

$(build):
	for p in $(packages) ; do \
	  touch $$p.build ;	\
	done

%.complete: %.build     
	cd $* ; ./install
	touch $*.complete

clean:  
	for p in $(packages) ; do \
	  $(MAKE) -f Makefile.$$p clean ; \
	  rm -f $$p.build $$p.packages $$p.complete ; \
	done


