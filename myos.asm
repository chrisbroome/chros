%include "include/int_key.mac"
%include "include/int_vid.mac"

%define BIOS_START              0x07c0
%define STACK_SPACE             0x1000
%define STACK_PARAGRAPH_OFFSET  (STACK_SPACE + 512) / 16

; starts at 0x0000 ends at 0x03ff, 4 bytes per entry, provides argument for jmp instruction
%define INTERRUPT_VECTOR_TABLE  0x0000
%define IVT_ENTRY(n)            (n << 2)
%define IVT_ENTRY_SEGMENT(n)    (IVT_ENTRY(n)+2)
%define IVT_ENTRY_OFFSET(n)     (IVT_ENTRY(n))
%define IVT_PTR_SEGMENT(n)      (n+2)
%define IVT_PTR_OFFSET(n)       (n)

%define BIOS_EQUIP_LIST		0x0410	; (word) BIOS equipment list data - bits 4-5 are 10 for color, 11 for mono
%define BIOS_KEY_SHIFT_STATUS	0x0417	; (byte) BIOS shift key status
%define BIOS_KEY_HEAD_PTR	0x041a	; (word) offset of keyboard buffer HEAD pointer
%define BIOS_KEY_TAIL_PTR	0x041c	; (word) offset of keyboard buffer TAIL pointer
%define BIOS_KEY_INPUT_QUEUE	0x041e	; (words) from 0x041e to 0x043c keyboard input queue in ASCII-scan code pairs
%define BIOS_CURRENT_VIDEO_MODE	0x0449	; (byte) current video mode (returned by int 10h, al=0fh)
%define BIOS_SCREEN_WIDTH	0x044a	; (word) screen width in characters
%define BIOS_VIDEO_PAGE_NUMBER	0x0462	; (byte) current display page number (returned by int 10h, al=0fh)
%define BIOS_TICKS_SINCE_MIDNIGHT	0x046c; (dword) time in ticks since midnight (approximately 18.2 ticks/second)
%define BIOS_CLOCK_PASSED_MIDNIGHT	0x0470; (byte) set to 1 when clock (above) passes midnight

%define INT_RTC		0x08 ; the real time clock interrupt (fires 18.2 times per second)

%macro _print_char 1
    push ax
    mov al, %1
    call print_char
    pop ax
%endmacro

[BITS 16]
    jmp BIOS_START:0x0000+start    ; make this a far jump so that cs:ip is set to 0x07c0:0x0000+start
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
    mov al, INT_RTC	; hook the clock intterupt
    lds bx, [old_clock_handler] ; load ds:bx with the old handler
    call save_interupt_vector_to_variable ; old_handler now contains the variable

    lds bx, [old_clock_handler] ; parameter to print_dword_ptr is ds:bx = dword pointer
    call print_dword_ptr
    call print_newline

    mov ax, 0x0040
    call print_ivt_entries
    call print_newline


    xor ax, ax
    sti                                             ; enable interrupts
.wtf:
    hlt
    jmp .wtf

    sti            ; Reenable hardware interrupts
.os_loop:
; TODO:  Add code to get disk information, check for bootable volumes, and transfer control to the boot volume
    hlt            ; Halt the processor and wait for hardware interrupts
    jmp .os_loop        ; Jump back up and halt the processor again

new_kb_handler:
    ;call dword [old_kb_handler]   ; call the old keyboard handler
;    call print_hex_16           ; print the scan code and character in hex
    pusha
      inc bx
    popa
    iret                        ; return from the interrupt

new_clock_handler:
    pusha
      call print_regs
      call print_newline
    popa
    iret

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
      pop ax                      ; restore ax
      shr dx, 4                   ; shift the mask right 4 times
      jcxz .end                   ; exit if cx == 0
      jmp .while_cx_not_zero      ; otherwise, do another iteration
.end:
    popa
    ret

; prints a dword ptr variable to the screen formatted as ffff:ffff
; ds is implicitly the segment
; variable offset is in bx
print_dword_ptr:
    pusha
      mov ax, [ds:bx+2] ; segment part of the address
      call print_hex_16 ; print the segment 
      _print_char ':'
      mov ax, [ds:bx] ; offset part of the address
      call print_hex_16 ; print the offset
    popa
    ret


; print all registers
print_regs:
    push ax             ; save ax
      push ax ; save ax again
	_print_char 'A'
      pop ax ; restore ax
      call print_hex_16
      _print_char 'B'
      mov ax, bx
      call print_hex_16
      _print_char 'C'
      mov ax, cx
      call print_hex_16
      _print_char 'D'
      mov ax, dx
      call print_hex_16
      _print_char 'S'
      mov ax, sp
      call print_hex_16
      _print_char 'B'
      mov ax, bp
      call print_hex_16
      _print_char 'S'
      mov ax, si
      call print_hex_16
      _print_char 'D'
      mov ax, di
      call print_hex_16
      _print_char 'D'
      mov ax, ds
      call print_hex_16
      _print_char 'E'
      mov ax, es
      call print_hex_16
    pop ax             ; restore ax
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
    mov ax, cx
    call print_ivt_entry ; destroys ax
    _print_char ' '
    inc cx
    cmp cl, ch           ; display the first ch intterupt handler addresses
    jne .ivt_entries
    pop cx
    pop ax
    ret
    

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
; parameters: ax = intterupt number
;             [ds:bx] = far dword pointer to variable
; returns dword [ds:bx] = old interrupt handler; *dsbx = old handler
save_interupt_vector_to_variable:
    pusha
    call get_interrupt_handler ; es:di contains a dword pointer to the intterupt handler address
    mov ax, [es:di+2] ; segment part of the address
    mov [ds:bx+2], ax ; 
    mov ax, [es:di]   ; offset part of the address
    mov [ds:bx], ax   ;
    popa
    ret

; replaces an interrupt handler with the specified handler
; parameters: ax = interrupt number
;             [ds:si] = far dword pointer to new intterupt handler 
; returns nothing
; example:
;     mov ax, 0x09
;     lds si, ds:new_handler
;     call hook_interrupt
hook_interrupt:
    call get_interrupt_handler ; es:di contains a dword pointer to the intterupt handler address
    push cx
    mov cx, 2
    cld ; clear the direction flag
    rep movsw ; [ds:si] = [es:di]
    pop cx
    ret

old_kb_handler:         dd  0       ; far pointer used to store the original keyboard handler
old_clock_handler:      dd  0       ; far pointer used to store the old clock handler
pad_boot:
    times 510-($-$$)    db  0       ; Pad remainder of boot sector with 0s
                        dw  0xAA55  ; The standard PC boot signature

