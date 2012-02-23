CC = $(CROSS_COMPILE)gcc
CFLAGS = -Wall -g

all: kernel kmain.o

kernel:

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	-rm -f kmain
	-rm -f *.o

.PHONY: all clean
