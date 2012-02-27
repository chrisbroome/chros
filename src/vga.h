#ifndef VGA_H
#define VGA_H
#include "inttypes.h"

typedef enum VGA_COLOR
{
  VGA_COLOR_FG_BLACK   = 0x00,
  VGA_COLOR_FG_BLUE    = 0x01,
  VGA_COLOR_FG_GREEN   = 0x02,
  VGA_COLOR_FG_CYAN    = 0x03,
  VGA_COLOR_FG_RED     = 0x04,
  VGA_COLOR_FG_MAGENTA = 0x05,
  VGA_COLOR_FG_YELLOW  = 0x06,
  VGA_COLOR_FG_GRAY    = 0x07,
  VGA_COLOR_FG_INTENSE = 0x08,
  VGA_COLOR_BG_BLACK   = 0x00,
  VGA_COLOR_BG_BLUE    = 0x10,
  VGA_COLOR_BG_GREEN   = 0x20,
  VGA_COLOR_BG_CYAN    = 0x30,
  VGA_COLOR_BG_RED     = 0x40,
  VGA_COLOR_BG_MAGENTA = 0x50,
  VGA_COLOR_BG_YELLOW  = 0x60,
  VGA_COLOR_BG_GRAY    = 0x70,
  VGA_COLOR_BG_INTENSE = 0x80,
  VGA_COLOR_DEFAULT    = VGA_COLOR_BG_BLACK | VGA_COLOR_FG_GRAY
} VGA_COLOR;

typedef struct cursor {
  int x;
  int y;
} cursor_t;

void cursor_init( cursor_t* c );
void vga_out_line( const char* src, cursor_t* cursor, VGA_COLOR color );

#endif

