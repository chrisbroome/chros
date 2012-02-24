CC = $(CROSS_COMPILE)gcc
LD = $(CROSS_COMPILE)ld
# add -Werror in a future enhancement
CFLAGS = -Wall -Wextra -nostdlib -fno-builtin -nostartfiles -nodefaultlibs -std=c99

FLOPPY_SIZE = 1474560

all: baseimage kernel.bin loader.o kmain.o gdt.o string.o

fddimage: baseimage

baseimage: stage1 stage2 pad kernel.bin
	-cat $+ > $@

kernel.bin: loader.o kmain.o gdt.o string.o
	-$(LD) -T linker.ld -o kernel.bin loader.o kmain.o

%.o: %.c
	-$(CC) $(CFLAGS) -c $< -o $@

loader.o: loader.fasm
	-fasm loader.fasm

stage1:

stage2:

pad:
	-dd bs=1 count=750 if=/dev/zero of=$@

clean:
	-rm -f kernel.bin
	-rm -f *.o
	-rm -f baseimage

.PHONY: all clean boot_files
