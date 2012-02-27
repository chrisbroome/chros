#ifndef MULTIBOOT_H
#define MULTIBOOT_H

#include "inttypes.h"

extern const uint32_t MULTIBOOT_EAX_MAGIC_NUMBER;

typedef enum MULTIBOOT_MAGIC_FLAG {
  MULTIBOOT_MAGIC_FLAG_ALIGN = 1 << 0,
  MULTIBOOT_MAGIC_FLAG_MEMORY = 1 << 1,
  MULTIBOOT_MAGIC_FLAG_VIDEO_INFO = 1 << 2
} MULTIBOOT_MAGIC_FLAG;

typedef struct mb_header mb_header;

int multiboot_check_flag( mb_header*, MULTIBOOT_MAGIC_FLAG );

#endif

