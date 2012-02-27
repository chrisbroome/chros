SUBMAKE = $(MAKE) $(MFLAGS)

all: kmain

kmain:
	-cd src; $(SUBMAKE)

clean:
	-cd src; $(SUBMAKE) clean

qk: src/kernel.bin
	-qemu -kernel $+

qfd: src/baseimage
	-qemu -fda $+

bfd: src/baseimage .bochsrc
	-bochs -q 'boot:floppy' 'floppya: 1_44=src/baseimage, status=inserted' 'cpu:i586'

run:
	-$(MAKE) qk

.PHONY: all run qk qfd clean
