SUBMAKE = $(MAKE) $(MFLAGS)

all: kmain

kmain:
	-cd src; $(SUBMAKE)

clean:
	-cd src; $(SUBMAKE) clean

run-qemu: src/kernel.bin
	-qemu -kernel src/kernel.bin

.PHONY: all run-qemu clean
