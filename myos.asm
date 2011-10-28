%include "include/int_key.mac"
%include "include/int_vid.mac"

BIOS_START              equ 0x07c0
STACK_SPACE             equ 0x1000
STACK_PARAGRAPH_OFFSET  equ (STACK_SPACE + 512) / 16

; starts at 0x0000 ends at 0x03ff, 4 bytes per entry, provides argument for jmp instruction
%define INTERRUPT_VECTOR_TABLE  0x0000
%define IVT_ENTRY(n)            (n << 2)
%define IVT_ENTRY_SEGMENT(n)    (IVT_ENTRY(n)+2)
%define IVT_ENTRY_OFFSET(n)     (IVT_ENTRY(n))
%define IVT_PTR_SEGMENT(n)      (n+2)
%define IVT_PTR_OFFSET(n)       (n)

BIOS_EQUIP_LIST			equ 0x0410 ; (word) BIOS equipment list data - bits 4-5 are 10 for color, 11 for mono
BIOS_KEY_SHIFT_STATUS		equ 0x0417 ; (byte) BIOS shift key status
BIOS_KEY_HEAD_PTR		equ 0x041a ; (word) offset of keyboard buffer HEAD pointer
BIOS_KEY_TAIL_PTR		equ 0x041c ; (word) offset of keyboard buffer TAIL pointer
BIOS_KEY_INPUT_QUEUE		equ 0x041e ; (words) from 0x041e to 0x043c keyboard input queue in ASCII-scan code pairs
BIOS_CURRENT_VIDEO_MODE		equ 0x0449 ; (byte) current video mode (returned by int 10h, al=0fh)
BIOS_SCREEN_WIDTH		equ 0x044a ; (word) screen width in characters
BIOS_VIDEO_PAGE_NUMBER		equ 0x0462 ; (byte) current display page number (returned by int 10h, al=0fh)
BIOS_TICKS_SINCE_MIDNIGHT	equ 0x046c ; (dword) time in ticks since midnight (approximately 18.2 ticks/second)
BIOS_CLOCK_PASSED_MIDNIGHT	equ 0x0470 ; (byte) set to 1 when clock (above) passes midnight

INT_RTC equ 0x08 ; the real time clock interrupt (fires 18.2 times per second)

%macro _print_char 1
    mov al, %1
    call print_char
%endmacro

ORG 0

[BITS 16]
    jmp word (BIOS_START):start    ; make this a far jump so that cs:ip is set to 0x07c0:start
    ; on entry, the dl register will contain number we are booting from
start:
    cli                             ; Clear hardware interrupts
    xor ax, ax                      ; zero out ax
    mov es, ax                      ; Set the extra segment to the start of memory
    mov ax, BIOS_START              ; The BIOS loads code here
    mov ds, ax                      ; Set data segment to where we're loaded
    add ax, STACK_PARAGRAPH_OFFSET  ; (4096 + 512) / 16 bytes per paragraph
    mov ss, ax                      ; Set stack segment
    mov sp, STACK_SPACE             ; Allocate stack space

; print values of all entries in the interrupt vector table
    mov ax, 0x0040 ; parameter for print_ivt_entries (print 40 entries)
    call print_ivt_entries
    call print_newline

; register our clock handler
;    mov al, INT_RTC	; hook the clock intterupt
;    lds bx, [old_clock_handler] ; load ds:bx with the old handler
;    call save_interupt_vector_to_variable ; old_handler now contains the variable

    push INT_RTC                          ; interrupt that we want to hook
    push dword [old_clock_handler]        ; output variable
    call save_interupt_vector_to_variable ; save the old hanlder in the old_clock_handler variable

    push dword [old_clock_handler]
    call print_dword_ptr
    call print_newline
;    lds bx, [old_clock_handler] ; parameter to print_dword_ptr is ds:bx = dword pointer
;    call print_dword_ptr
;    call print_newline

    mov ax, 0x0040
    call print_ivt_entries
    call print_newline

    call print_regs

    xor ax, ax
    sti                                             ; enable interrupts

.os_loop:
; TODO:  Add code to get disk information, check for bootable volumes, and transfer control to the boot volume
    hlt            ; Halt the processor and wait for hardware interrupts
    jmp .os_loop        ; Jump back up and halt the processor again

new_kb_handler:
    ;call dword [old_kb_handler]   ; call the old keyboard handler
;    call print_hex_16           ; print the scan code and character in hex
;    pusha
;      inc bx
;    popa
;    iret                        ; return from the interrupt

new_clock_handler:
;    pusha
;      call print_regs
;      call print_newline
;    popa
;    iret

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

; get an interrupt handler
; parameters: ax = interrupt number (only al used as input)
; returns es:di = interrupt handler
; destroys di, es
get_interrupt_handler:
    push ax
      push bx
        cli
        and ax, 0x00ff ; mask out ah
        shl ax, 2 ; multiply the interrupt number by 4 to get the memory location
        mov bx, ax ; bx now contains the offset into memory of the interrupt vector for al
        xor ax, ax  ; zero out ax so we can set es to 0
        mov es, ax  ; set es to 0
        les di, [es:bx] ; es:di = [es:bx]...in C, we'd have int **esbx, *esdi; esdi = *esbx;
        sti
      pop bx
    pop ax
    ret

; saves an intterupt vector to the specified variable
; parameters: [bp+2] intterupt number
;             [bp+4] far dword pointer to output variable
; returns dword [bp+4] = old interrupt handler; *bpp4 = old handler
save_interupt_vector_to_variable:
%push mycontext       ; save the current NASM lexical context
%stacksize small      ; using an enter instruction (saves bp)
%assign %$localsize 0 ; must be declared so that %local definitions work
%arg i_num:word, retval:dword
  enter %$localsize, 0 ; set up a stack frame and reserve space for input param and output param
  pusha
    mov ax, [i_num]   ; move the value of i_num to ax
    shl ax, 2         ; multiply the interrupt number by 4 to get the memory location
    mov bx, ax        ; bx now contains the offset into memory of the interrupt vector for al
    xor ax, ax        ; ax = 0
    mov es, ax        ; es = 0
    les di, [es:bx]   ; es:di = [es:bx] - C code: int **esbx, *esdi; esdi = *esbx;
    ;lds bx, [es:ret_val] ; load [ds:bx] with the address of [ret_val]
    mov ax, [es:di+2]  ; segment part of the address
    mov [retval+2], ax ; 
    mov ax, [es:di]    ; offset part of the address
    mov [retval], ax   ;
  popa
  ret 2+8
%pop

; replaces an interrupt handler with the specified handler
; parameters: ax = interrupt number
;             [ds:si] = far dword pointer to new intterupt handler 
; returns nothing
; example:
;     mov ax, 0x09
;     lds si, ds:new_handler
;     call hook_interrupt
hook_interrupt:
;  pusha
;    call get_interrupt_handler ; es:di contains a dword pointer to the intterupt handler address
;  popa
;  ret

; handles single stepping while debugging code
trap_routine:
  cli
    call print_regs
  sti
  iret

reg_name_ax       db 'ax bx cx dx: ',0
reg_name_bp       db 'bp sp si di: ',0
reg_name_ds       db 'ds es cs ip: ',0

;old_trap_handler  dd 0       ; far pointer used to store the old trap interrupt handler
old_clock_handler dd 0       ; far pointer used to store the old clock handler
;old_kb_handler    dd 0       ; far pointer used to store the original keyboard handler

pad_boot:
    times 510-($-$$)    db 0       ; Pad remainder of boot sector with 0s
                        dw 0xAA55  ; The standard PC boot signature

;    times 1474560-512 db 0 ; pad the remainder of the floppy
