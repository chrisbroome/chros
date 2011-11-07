; Copyright 2011 Christopher Broome

; init will be loaded by loader.asm

org 0x0 ; offset to 0, we will set segments later
use16   ; we are still in real mode here, but we'll switch later

; interrupts
INT_BIOS_DISK  = 0x13
INT_BIOS_VIDEO = 0x10

; our loader loads us at physical address 0x8000
START_ADDRESS = 0x8000
  jmp main   ; jump to the main program

main:
  cli ; clear interrupts
             ; align all our segments
  mov ax, cs ; set ax = cs
  mov ds, ax ; set ds = cs
  mov es, ax ; set es = cs

  push loading_message
  call puts

  cli     ; clear all interrupts and halt the processor
  hlt     ; halt the system

; outputs a null terminated string to the console
; the first parameter is a pointer to the string
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
loading_message db 'Loading OS...', 0
times (18*512)-$ db 0