#include "kmain.h"

VGA_COLOR _color_good    = VGA_COLOR_FG_GREEN | VGA_COLOR_FG_INTENSE;
VGA_COLOR _color_bad     = VGA_COLOR_FG_RED | VGA_COLOR_FG_INTENSE;
VGA_COLOR _color_neutral = VGA_COLOR_FG_BLUE | VGA_COLOR_FG_INTENSE;
VGA_COLOR _color_default = VGA_COLOR_FG_GRAY;

// declare a global cursor
cursor_t _c;

void out_vid( const char* msg, VGA_COLOR col )
{
  vga_out_line( msg, &_c, col );
}

void do_exit()
{
  //
  for( uint8_t i=0; i < 16; ++i )
  {
    out_vid( "exiting kernel", i );
  }
}

void do_multiboot_check( mb_header* mbh, uint32_t magic )
{
  // make sure we loaded from the multiboot loader
  if( magic != MULTIBOOT_EAX_MAGIC_NUMBER )
  {
    // not loaded by multiboot
    out_vid( "Not loaded by multiboot", _color_bad );
  }
  else
  {
    const char* align = multiboot_check_flag( mbh, MULTIBOOT_MAGIC_FLAG_ALIGN ) ? "align:1" : "align:0";
    const char* mem   = multiboot_check_flag( mbh, MULTIBOOT_MAGIC_FLAG_MEMORY ) ? "mem_info:1" : "mem_info:0";
    const char* video = multiboot_check_flag( mbh, MULTIBOOT_MAGIC_FLAG_VIDEO_INFO ) ? "vid_info:1" : "vid_info:0";
    // output mbd values
    out_vid( "multiboot values", _color_good );
    
    out_vid( align, _color_default );
    out_vid( mem, _color_default );
    out_vid( video, _color_default );
  }
}

void kmain_init()
{
  // initialize the cursor
  cursor_init( &_c );
}

int kmain( mb_header *mbh, uint32_t magic )
{
  // initialize things
  kmain_init();
  
  // indicate that we loaded
  out_vid( "loaded", _color_neutral );

  // checkfor multiboot values and output messages if present
  do_multiboot_check( mbh, magic );

  // we got to here.  awesome
  out_vid( "passed", _color_good );

  // perform the exit routine
  do_exit();
  
  // normal kernal return code
  return 0;
}

