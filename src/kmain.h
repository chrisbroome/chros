#include "inttypes.h"
#include "multiboot.h"
#include "gdt.h"
#include "vga.h"

void do_exit();
void do_multiboot_check( mb_header* mbd, uint32_t magic );

int kmain( mb_header *mbh, uint32_t magic );

