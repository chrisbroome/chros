; First 1 MB of memory (addresses in hex)
; Description                      Start End
; -------------------------------- ----- -----
; Motherboard BIOS                 f0000 fffff <--- Sometimes bios extends further down to e0000 as in BIOS-bochs-latest
; Mapped Hardware and Misc         c8000 effff 
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

FREE_RAM_START = 0x500
STACK_TOP      = 0x1000
STACK_SIZE     = STACK_TOP - FREE_RAM_START

use16

  jmp far 0x07c0:main ; The BIOS loads code at physical address 0x7c00.
                      ; By using a far jump and specifying the segment
                      ; and offset, we are effectively setting cs to
                      ; 0x7c0 and ip to 0.  We can use this cs value
                      ; to align other segment registers.
main:
  cli                    ; Clear all interrupts for initialization
  mov ax, cs             ; Initialize other segments to be the same as cs
  mov ds, ax             ; ds = cs
  mov es, ax             ; es = cs
  mov ax, FREE_RAM_START ; Set up our stack
  mov ss, ax             ; Stack segment starts at FREE_RAM_START to
                         ; ensure that [ss:sp] never points to a used
                         ; BIOS memory location
  mov sp, STACK_SIZE     ; This gives us STACK_SIZE bytes for our stack
  mov [boot_device], dl  ; On boot, dl contains the device number that
                         ; we are booting from (see table for details)

  sti                  ; Reenable interrupts for normal processing

  push loading_message ; parameter for puts
  call puts            ; put the string to the console

os_loop:
  hlt                 ; halt the processor (just process interrupts)
  jmp os_loop         ; after interrupt is processed, halt again

; outputs a null terminated string to the console
; si contains a pointer to the string
puts:
label string_addr at bp+4
  enter 0, 0      ; set up a stack frame
  push bx
  push si
  pushf
  mov ah, 0x0e    ; BIOS function to output a character
  mov bx, 0x0007  ; 0 page, 7 attribute (normal text color)
  mov si, [string_addr] ; move the address to si
  cld
.loop:
  lodsb           ; load al with the byte at [ds:si]
                  ; and increment si
  cmp al, 0       ; if al == 0
  je .done        ; goto .done
                  ; else
  int 0x10        ; call the BIOS video interrupt to output the character
  jmp .loop       ; loop again
.done:
  popf
  pop si
  pop bx
  leave           ; restore bp
  ret 2           ; pop parameters ourselves

; null terminated strings
loading_message db 'Loading myos...', 0
; 
boot_device db 0         ; will store the device that we booted from

times 510-$ db 0         ; 0 pading to make the size exactly 512 bytes
boot_signiture dw 0xaa55 ; boot signiture
