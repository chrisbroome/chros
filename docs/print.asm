%include "include/int_vid.mac"

%macro _print_char 1
    mov al, %1
    call print_char
%endmacro

; INT_VID_TTY_OUTPUT              0x0E    
;       AH = 0Eh
;       AL = character to write
;       BH = page number
;       BL = foreground color (graphics modes only)
print_char:
  pusha
    mov ah, INT_VID_TTY_OUTPUT
    mov bx, 0x0007
    int INT_VID
  popa
  ret
    
; puts the cursor on a newline
print_newline:
  pusha
    mov bx, 0x0007
    mov ah, INT_VID_TTY_OUTPUT
    mov al, 0x0a    ; CR
    int INT_VID
    mov al, 0x0d    ; LF
    int INT_VID
  popa
  ret

; ax = number to write to the screen
print_hex_16:
  pusha
    mov bx, 0x0007
    mov cx, 0x0010 ; shift amount (must be a multiple of 4)
    mov dx, 0xf000 ; mask
.while_cx_not_zero:
    push ax
      sub cl, 4   ; subtract 4 from cl on each pass
      and ax, dx  ; mask out the appropriate digit
      shr ax, cl  ; shift ax right cl times
.correct_digit:
      add al, '0'                 ; correct digit for display
      cmp al, '9'                 ; is digit a number?
      jle .output                 ; digit is a number
      add al, 'a'-('9' + 1)       ; digit is a letter
.output:
      mov ah, INT_VID_TTY_OUTPUT  ; output the character
      int INT_VID                 ; print the digit
    pop ax                 ; restore ax
    shr dx, 4              ; shift the mask right 4 times
    jcxz .end              ; exit if cx == 0
    jmp .while_cx_not_zero ; otherwise, do another iteration
.end:
  popa
  ret

; prints a dword ptr variable to the screen formatted as ffff:ffff
; ds is implicitly the segment
; parameters: [bp+4] dword pointer offset
;             [bp+6] dword pointer segment
print_dword_ptr:
  enter 0, 0
  pusha
    mov ax, [bp+6] ; segment part of the address
    call print_hex_16 ; print the segment 
    _print_char ':'
    mov ax, [bp+4] ; offset part of the address
    call print_hex_16 ; print the offset
  popa
  ret


; print all registers - must be used with a call instruction as in call print_regs
print_regs:
  enter 0, 0 ; enter subroutine (sets up stack frame so that old IP can be accessed with [bp+2])
    push ax             ; save ax
; print ax, bx, cx, dx
      push reg_name_ax  ; offset of reg_name_ax variable (ds is implicitly assumed to be the segment)
      call print_string ; print the string
      call print_hex_16 ; print the value of ax

      _print_char ' '
      mov ax, bx	; set ax = bx
      call print_hex_16 ; print bx

;      push reg_name_cx
;      call print_string
      _print_char ' '
      mov ax, cx
      call print_hex_16

;      push reg_name_dx
;      call print_string
      _print_char ' '
      mov ax, dx
      call print_hex_16

      call print_newline

; print bp and sp
      push reg_name_bp
      call print_string
      mov ax, bp
      call print_hex_16

;      push reg_name_sp
;      call print_string
      _print_char ' '
      mov ax, sp
      call print_hex_16

; print si and di
;      push reg_name_si
;      call print_string
      _print_char ' '
      mov ax, si
      call print_hex_16

;      push reg_name_di
;      call print_string
      _print_char ' '
      mov ax, di
      call print_hex_16

      call print_newline

; print es and ds
      push reg_name_ds
      call print_string
      mov ax, ds
      call print_hex_16

;      push reg_name_es
;      call print_string
      _print_char ' '
      mov ax, es
      call print_hex_16

;      call print_newline

; print cs and ip
;      push reg_name_cs
;      call print_string
      _print_char ' '
      mov ax, cs
      call print_hex_16

;      push reg_name_ip
;      call print_string
      _print_char ' '
      mov ax, [bp+2] ; the return address of the ret instruction, i.e. the instruction pointer before the proc was called
      call print_hex_16
      call print_newline

    pop ax             ; restore ax
    leave
  ret

; prints the value at the specified interrupt vector table entry
; parameters: ax = interrupt number (only al used as input, but ax destroyed)
print_ivt_entry:
  push ax
    push es
      push di
	call get_interrupt_handler
	mov ax, es
	call print_hex_16
	_print_char ':'
	mov ax, di
	call print_hex_16
      pop di
    pop es
  pop ax
  ret

; prints the first al ivt entries
; parameters: ax = how many entries to print
print_ivt_entries:
  push ax
    push cx
    ; print values of all entries in the interrupt vector table
      xor cx, cx          ; set cx = 0
      mov ch, al          ; set ch = al
.ivt_entries:
      mov ax, cx           ; ax = interrupt number
      call print_ivt_entry ; print the ivt entry at the speicified interrupt number
      _print_char ' '
      inc cx
      cmp cl, ch           ; display the first ch intterupt handler addresses
      jne .ivt_entries
    pop cx
  pop ax
  ret

; prints the null (0) terminated string at ds:[bp+4]
; note that ds is implicitly assumed to be correct
; parameters: [bp+4] word offset of string value to print
print_string:
  enter 0, 0 ; set up a stack frame
    pusha ; save all registers
      pushf ; save the flags register
        mov si, [bp+4] ; offset of string
        cld ; clear the direction flag so that we're looping forwards
.loop:
        lodsb ; load al with the value of the string
        cmp al, 0
        je .done
        call print_char ; print the character in al
        jmp .loop
.done:
      popf ;
    popa
  leave
  ret 2
