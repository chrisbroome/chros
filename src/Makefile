CC = $(CROSS_COMPILE)gcc
LD = $(CROSS_COMPILE)ld

ASM = fasm

# add -Werror in a future enhancement
CFLAGS = -Wall -Wextra -nostdlib -fno-builtin -nostartfiles -nodefaultlibs -std=c99

OBJ_FILES = loader.o kmain.o vga.o gdt.o multiboot.o string.o

FLOPPY_SIZE = 1474560

all: fddimage

fddimage: baseimage

baseimage: stage1 stage2 pad kernel.bin
	-cat $+ > $@

kernel.bin: $(OBJ_FILES)
	-$(LD) -T linker.ld -o $@ $+

%.o: %.c
	-$(CC) $(CFLAGS) -c $< -o $@

loader.o: loader.fasm
	-$(ASM) $+ $@

stage1:

stage2:

pad:
	-dd bs=1 count=750 if=/dev/zero of=$@

clean:
	-rm -f kernel.bin
	-rm -f *.o
	-rm -f baseimage

.PHONY: all clean boot_files
