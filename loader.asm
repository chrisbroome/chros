; Copyright 2011 Christopher Broome

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

; OS Specific Values               Start End
; -------------------------------- ----- -----
; 2nd Stage Bootloader             07e00 80000
; Boot Sector (Same as above)      07c00 07dff
; Our stack                        00500 00fff

OS_FLAT_ADDR_START = 0x7e00
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
  mov ax, FREE_RAM_START ; Set up our stack
  mov ss, ax             ; Stack segment starts at FREE_RAM_START to
                         ; ensure that [ss:sp] never points to a used
                         ; BIOS memory location
  mov sp, STACK_SIZE     ; This gives us STACK_SIZE bytes for our stack
  mov [boot_device], dl  ; On boot, dl contains the device number that
                         ; we are booting from (see table for details)

  mov ax, 0x800  ; the segment where we'll load our 2nd stage
  mov es, ax     ; es = 0x800
                 ; we'll be loading data to physical address 0x8000
  xor bx, bx     ; set bx = 0, data is read to es:bx

  mov si, 3      ; we'll try reading data 3 times before giving up

; reset the disk controller in preparation for loading 2nd stage bootloader
reset_disk_controller:
  mov cx, 5             ; retry read 5 times
.reset_loop:
  xor ax, ax            ; zero out ax
  mov dl, [boot_device] ; dl = drive to reset
  int INT_BIOS_DISK     ; bios disk access interrupt
  dec cx                ; carry flag not altered
  jcxz .fatal           ; unable to reset drive
  jc .reset_loop        ; if carry was set, there was an error, so try it again
  jmp read_os_sectors   ; otherwise, we're reset
.fatal:
  push disk_reset_error ; let the user know we couldn't reset the controller
  call puts             ; put the string to the screen
  jmp os_loop           ; unable to reset disk controller.  jump to halt loop

; reads the first sectors_per_track sectors into memory at 0x8000
read_os_sectors:
  dec si        ; si contains the number of times we've tried to read
  cmp si, 0     ; if si == 0
  je .fatal     ; bail out
  mov ah, 0x02  ; function to read sector(s) into memory
  mov al, sectors_per_track ; read 18 sectors at a time: 18*512=9216 bytes per read
  mov ch, 0     ; low 8 bits of cylinder number: 0
  mov cl, 2     ; high 2 bits of cylinder (bits 6-7): 0, sector 2 (bits 0-5)
  mov dh, 0     ; reading from head 0 (first head)
                ; read from the boot device
  mov dl, [boot_device]

  int INT_BIOS_DISK ; call the BIOS routine to read data
  jc reset_disk_controller ; failed to read.  reset controller and try again
  jmp 0x0800:0   ; otherwise, jump to our 2nd stage loader
.fatal:
  push disk_read_error ; print a message indicating that we couldn't read
  call puts            ; 

os_loop:
  cli                 ; clear interrupts
  hlt                 ; halt the processor (just process interrupts)
  jmp os_loop         ; after interrupt is processed, halt again

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

disk_reset_error db 'Disk reset error', 0
disk_read_error  db 'Disk read error', 0

boot_device db 0         ; will store the device that we booted from

times 510-$ db 0         ; 0 pading to make the size exactly 512 bytes
boot_signiture dw 0xaa55 ; boot signiture
