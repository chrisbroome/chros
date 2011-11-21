bin_PROGRAMS = os kmain

BINDIR = ../bin
OBJDIR = ../obj
OBJCOPYFLAGS = --only-section=.text --output-target binary

os_SOURCES = loader.fasm init.fasm

kmain_SOURCES = kmain.c
kmain_CPPFLAGS = -I. -I../include
kmain_CFLAGS = -nostdinc -m32 -masm=intel -Wall

all: kmain os

kmain.o: kmain.c
	$(CC) -I. -I../include -nostdinc -m32 -masm=intel -Wall -c $< -o $@

kmain: kmain.o
	objcopy $(OBJCOPYFLAGS) $< $(BINDIR)/$@.bin

$(BINDIR)/%.bin: %.fasm
	fasm $< $(BINDIR)/$@

os: $(BINDIR)/loader.bin $(BINDIR)/init.bin kmain
	cat $(BINDIR)/loader.bin $(BINDIR)/init.bin > $(BINDIR)/$@

.PHONY: all