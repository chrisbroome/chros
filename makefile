objdir = obj
srcdir = src
bindir = bin
asm = fasm
sources = loader.fasm init.fasm
objects = ${addprefix ${objdir}/, ${sources:.fasm=}}
executable = os.bin

all: ${executable}

clean:
	-@rm ${objdir}/* ${bindir}/${executable}

${objects}: ${addprefix ${srcdir}/, ${sources}}
	${asm} $< $@

${executable}: ${objects}
	cat ${objects} > ${bindir}/$@

.PHONY: all clean
