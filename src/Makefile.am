bin_PROGRAMS = os.bin
os_bin_SOURCES = loader.fasm init.fasm
os_bin_INCLUDEDIR = include
os_bin_BINDIR = ../bin

all: os.bin

%.bin: %.fasm
	fasm $< $@

os.bin: loader.bin init.bin
	cat loader.bin init.bin > ../bin/$@

.PHONY: all