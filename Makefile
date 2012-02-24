SUBMAKE = $(MAKE) $(MFLAGS)

all: kmain

kmain:
	-cd src; $(SUBMAKE)

clean:
	-cd src; $(SUBMAKE) clean

qk: src/kernel.bin
	-qemu -kernel src/kernel.bin

qfd: src/baseimage
	-qemu -fda src/baseimage

.PHONY: all run-qemu clean
