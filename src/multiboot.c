/*
* COPYRIGHT 2012 Christopher Broome
*
* multiboot.c
*/
#include "multiboot.h"

const uint32_t MULTIBOOT_EAX_MAGIC_NUMBER = 0x2badb002;
const uint32_t _mb_magic_magic_number = 0x1badb002;

// magic header
typedef struct _mb_magic {
  uint32_t magic;    // must be the magic number 0x1badb002
  uint32_t flags;    // various flags that can be set
  uint32_t checksum; // unsigned addition of magic, flags, and zero must equal zero
} _mb_magic;

// address header
typedef struct _mb_address {
  uint32_t header_addr;
  uint32_t load_addr;
  uint32_t load_end_addr;
  uint32_t bss_end_addr;
  uint32_t entry_addr;
} _mb_address;

// graphics header
typedef struct _mb_graphics {
  uint32_t mode_type;
  uint32_t width;
  uint32_t height;
  uint32_t depth;
} _mb_graphics;

// internal structs that represent the binary format of the multiboot header
typedef struct mb_header {
  _mb_magic    magic;    //
  _mb_address  address;  // if magic.flags_16 is set
  _mb_graphics graphics; // if magic.flags_2 is set
} _mb;

void _mb_magic_calculate_checksum( _mb_magic* x ) { x->checksum = -(x->magic + x->flags); }

void _mb_magic_init( _mb_magic* x )
{
  x->magic    = _mb_magic_magic_number;
  x->flags    = 0;
  _mb_magic_calculate_checksum( x );
}

void _mb_magic_set_flags( _mb_magic* x, uint32_t flags )
{
  x->flags = flags;
  _mb_magic_calculate_checksum( x );
}

void _mb_address_init( _mb_address* x )
{
  x->header_addr   = 0;
  x->load_addr     = 0;
  x->load_end_addr = 0;
  x->bss_end_addr  = 0;
  x->entry_addr    = 0;
}

void _mb_graphics_init( _mb_graphics* x )
{
  x->mode_type = 0;
  x->width     = 0;
  x->height    = 0;
  x->depth     = 0;
}

void multiboot_init( _mb* x )
{
  _mb_magic_init( &(x->magic) );
  _mb_address_init( &(x->address) );
  _mb_graphics_init( &(x->graphics) );
}

// public methods
int multiboot_check_flag( mb_header* x, MULTIBOOT_MAGIC_FLAG f )
{
  return ( x->magic.flags & f );
}

