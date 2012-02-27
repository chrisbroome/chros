#include "vga.h"

void cursor_init( cursor_t* c )
{
  c->x = 0;
  c->y = 0;
}

uint8_t* _get_vram_pointer()
{
  return (uint8_t*)0xb8000;
}

void vga_out_line( const char* src, cursor_t* cursor, VGA_COLOR color )
{
  uint8_t* const dest = _get_vram_pointer();
  for( unsigned int i = 0; src[i] != 0; ++i )
  {
    unsigned int cursor_offset = cursor->y * 80 * 2 + cursor->x;
    unsigned int dest_offset = (i*2) + cursor_offset;
    dest[dest_offset] = src[i];
    dest[dest_offset + 1] = color;
  }
  cursor->y++;
}

