#include "gdt.h"

const unsigned int MULTIBOOT_MAGIC = 0x2badb002;
const unsigned char* LOADED = "loaded";
const unsigned char* FAILED = "failed";
const unsigned char* PASSED = "passed";

typedef enum VGA_COLOR
{
  VGA_COLOR_BLACK = 0x00,
  VGA_COLOR_BLUE = 0x01,
  VGA_COLOR_GREEN = 0x02,
  VGA_COLOR_RED = 0x04
} VGA_COLOR;

void out_video( unsigned char *dest, unsigned char* src, unsigned int length, VGA_COLOR color )
{
  for( unsigned int i = 0; i < length; ++i )
  {
    dest[i*2] = src[i];
    dest[i*2+1] = color;
  }
}

int kmain( void *mbd, unsigned int magic )
{
  unsigned char *videoram = (unsigned char*)0xb8000;
  out_video( videoram, LOADED, 7, VGA_COLOR_BLUE );

  // make sure we loaded from the multiboot loader
  if( magic != MULTIBOOT_MAGIC )
  {
    // something went wrong.  we failed
    out_video( &videoram[80*2], FAILED, 7, VGA_COLOR_RED );
    //videoram[0] = 'F';
    //videoram[1] = 0x04;
    return -1;
  }
  
  // we got to here.  awesome
  out_video( &videoram[80*2], PASSED, 7, VGA_COLOR_GREEN );
  return 0;
}

