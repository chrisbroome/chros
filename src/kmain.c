#include "inttypes.h"
#include "gdt.h"

const uint32_t MULTIBOOT_MAGIC = 0x2badb002;
const char* LOADED = "loaded";
const char* FAILED = "failed";
const char* PASSED = "passed";
const char* EXITING = "exiting";
uint8_t* videoram = (uint8_t*)0xb8000;

typedef enum VGA_COLOR
{
  VGA_COLOR_FG_BLACK   = 0x00,
  VGA_COLOR_FG_BLUE    = 0x01,
  VGA_COLOR_FG_GREEN   = 0x02,
  VGA_COLOR_FG_RED     = 0x04,
  VGA_COLOR_FG_INTENSE = 0x08,
  VGA_COLOR_BG_BLACK   = 0x00,
  VGA_COLOR_BG_BLUE    = 0x10,
  VGA_COLOR_BG_GREEN   = 0x20,
  VGA_COLOR_BG_RED     = 0x40,
  VGA_COLOR_BG_INTENSE = 0x80
} VGA_COLOR;

typedef struct cursor {
  int x;
  int y;
} cursor_t;

void cursor_init( cursor_t* c )
{
  c->x = 0;
  c->y = 0;
}

void out_video_line( uint8_t* dest, const char* src, unsigned int length, cursor_t* cursor, VGA_COLOR color )
{
  for( unsigned int i = 0; i < length; ++i )
  {
    unsigned int cursor_offset = cursor->y * 80 * 2 + cursor->x;
    unsigned int dest_offset = (i*2) + cursor_offset;
    dest[dest_offset] = src[i];
    dest[dest_offset + 1] = color;
  }
  cursor->y++;
}

int kmain( void *mbd, uint32_t magic )
{
  // declare a cursor
  cursor_t c;

  // initialize the cursor
  cursor_init( &c );

  // get a pointer to the cursor
  cursor_t* cursor = &c;

  // write a message out to videoram indicating that we loaded
  out_video_line( videoram, LOADED, 6, cursor, VGA_COLOR_FG_BLUE | VGA_COLOR_FG_INTENSE );

  // make sure we loaded from the multiboot loader
  if( magic != MULTIBOOT_MAGIC )
  {
    // something went wrong.  we failed
    out_video_line( videoram, FAILED, 6, cursor, VGA_COLOR_FG_RED | VGA_COLOR_FG_INTENSE );
    //videoram[0] = 'F';
    //videoram[1] = 0x04;
    return -1;
  }
  
  // we got to here.  awesome
  out_video_line( videoram, PASSED, 6, cursor, VGA_COLOR_FG_GREEN | VGA_COLOR_FG_INTENSE );


  // about to exit.  might as well print a message
  out_video_line( videoram, EXITING, 7, cursor
                , VGA_COLOR_FG_BLUE
                | VGA_COLOR_FG_GREEN
                | VGA_COLOR_FG_RED
                | VGA_COLOR_FG_INTENSE
                | VGA_COLOR_BG_BLUE
                | VGA_COLOR_BG_INTENSE );
  return 0;
}

