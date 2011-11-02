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

BIOS_FLAT_ADDR_START  = 0x7c00
FREE_RAM_START        = 0x500
STACK_TOP             = 0x1000
STACK_SIZE            = STACK_TOP - FREE_RAM_START
INT_BIOS_DISK         = 0x13
INT_BIOS_VIDEO        = 0x10

BYTES_PER_SECTOR      = 512
SECTORS_PER_TRACK     = 18
HEAD_TO_READ          = 0   ; We're always going to read head 0 while booting
DRIVE_TO_READ         = 0   ; Read drive 0 (we're using a floppy)

; We'll be loading our 2nd stage loader here. This yields 0x6c00 
; (0x7c00 - 0x1000) contiguous bytes of space for our 2nd stage loader.
; This means we can read 0x0036 (0x6c00 / 0x0200) sectors from disk to
; contiguous RAM.  However, because floppy disk tracks only have 18
; (decimal) sectors per track, we have to divide our reads into sub-reads
; for each track.  Luckily, 0x0036 / 0x0012 gives exactly 3 tracks, so this
; works for our current choice of start address.  This would have to be
; adjusted if we were to load to a different address.
SECOND_STAGE_LOAD_FLAT_ADDR = STACK_TOP
CONTIGUOUS_SECOND_STAGE_RAM = BIOS_FLAT_ADDR_START - SECOND_STAGE_LOAD_FLAT_ADDR
TOTAL_SECTORS_TO_READ       = CONTIGUOUS_SECOND_STAGE_RAM / BYTES_PER_SECTOR
NUMBER_OF_TRACKS_TO_READ    = TOTAL_SECTORS_TO_READ / SECTORS_PER_TRACK

use16

  jmp near loader_main ; this is a near jump so that it only takes up 3 bytes
                       ; and leaves 8 bytes for the OEM identifier

; the name of the operating system
oem_string            db "My OS   " ; must be exactly 8 bytes

; the bios parameter block starts at offset 0x000b

; OEM BIOS Parameter Block (Fat 12)
bytes_per_sector      dw 512
sectors_per_cluster   db 1
reserved_sectors      dw 1
numbers_of_FATs       db 2
root_entries          dw 224
small_sectors         dw 2880
media_descriptor      db 0xf0
sectors_per_FAT       dw 9
sectors_per_track     dw 18
header_per_cylinder   dw 2
hidden_sectors        dd 0
large_sectors         dd 0

; Extended BIOS Parameter Block
physical_drive_number db 0x00
current_head          db 0
ext_boot_signiture    db 0x29
volume_serial         dd 0
volume_label          db "BOOT FLOPPY"
file_system_id        db "FAT12   "

loader_main:
  jmp far 0x07c0:actual_loader_main
                             ; The BIOS loads code at physical address 0x7c00.
                             ; By using a far jump and specifying the segment
                             ; and offset, we are effectively setting cs to
                             ; 0x7c0 and ip to 0.  We can use this cs value
                             ; to align other segment registers.
actual_loader_main:
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

; reset the floppy controller in preparation for loading 2nd stage bootloader
reset_floppy:
  xor ax, ax        ; zero out ax
  mov dl, 0         ; dl = drive to reset
  int INT_BIOS_DISK ; bios disk access interrupt
  jc reset_floppy   ; if carry was set, there was an error, so try it again

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
  int INT_BIOS_VIDEO  ; call the BIOS video interrupt to output the character
  jmp .loop       ; loop again
.done:
  popf
  pop si
  pop bx
  leave           ; restore bp
  ret 2           ; pop parameters ourselves

; null terminated strings
loading_message db 'Loading myos...', 0
; disk_read_error db 'Disk read error...', 0x0a, 0x0d, 0
; 
boot_device db 0         ; will store the device that we booted from

times 510-$ db 0         ; 0 pading to make the size exactly 512 bytes
boot_signiture dw 0xaa55 ; boot signiture
