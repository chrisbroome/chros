
SUBMAKE = $(MAKE) $(MFLAGS)

all: kmain

kmain:
	-cd src; $(SUBMAKE)

clean:
	-cd src; $(SUBMAKE) clean

.PHONY: all clean
