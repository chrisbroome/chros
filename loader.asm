; First 1 MB of memory (addresses in hex)
; Description                      Start End
; -------------------------------- ----- -----
; Motherboard BIOS                 f0000 fffff <--- Sometimes overlap as in BIOS-bochs-latest
; Mapped Hardware and Misc         c8000 effff <----^
; Video BIOS                       c0000 c7fff
; Video Memory                     a0000 bffff
; Extended BIOS Data Area          9fc00 9ffff
; RAM (free for use if it exists)  80000 9fbff
; RAM (free for use)               07e00 7ffff
; Boot Sector                      07c00 07dff
; RAM (free for use)               00500 07bff
; BIOS Data                        00400 004ff
; Real Mode Interrupt Vector Table 00000 003ff

; Special BIOS Data Addresses
; Description                            address size
; -------------------------------------- ------- ----
; IO port for COM1 serial                0400    word
; IO port for LPT1 parallel              0408    word
; EBDA base address >> 4 (usually!)      040E    word
; packed bit flags for detected hardware 0410    word
; Display Mode                           0449    byte
; base IO port for video                 0463    2 bytes, taken as a word
; # of IRQ0 timer ticks since boot       046C    word
; # of hard disk drives detected         0475    byte
; last keyboard LED/Shift key state      0497    byte

use16

  jmp far 0x07c0:os_loop

os_loop:

  hlt
  jmp os_loop

times 510-$ db 0
boot_signiture dw 0xaa55 ; boot signiture
