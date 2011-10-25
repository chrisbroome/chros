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
; code for setting up the keyboard handler

;    sti
;    mov al, VIDEO_MODE_TEXT_80x25
;    mov ah, INT_VID_SET_VIDEO_MODE
;    int INT_VID
;    cli
; hook the keyboard event interrupt (key_up or key_down)

;    mov ax, word [es:(IVT_ENTRY(INT_KEYEVENT)+2)]   ; read the segment part of the address
;    mov word [old_kb_handler+2], ax                 ; store the segment part of the address
;    call print_hex_16                               ; 
;    mov al, ':'                                     ; 
;    call print_char                                 ; 

;    mov ax, word [es:(IVT_ENTRY(INT_KEYEVENT))]     ; read the offset part of the address
;    mov word [old_kb_handler], ax                   ; store the offset part of the address 
;    call print_hex_16                               ; 
    
;    lds si, [new_kb_handler]                        ; load [ds:si] with the new keyboard handler
;    mov di, IVT_ENTRY(INT_KEYEVENT)                 ; load [es:di] with the address of the appropriate interrupt vector
;    mov cx, 4                                       ; we'll be copying 4 bytes
;    cld                                             ; clear the direction flag
;    rep movsb                                       ; move the bytes at [ds:si] to [es:di]
    
;    call print_newline

    call print_regs
    call print_newline
; print ds:si
    push ds
    push es
    lds si, [es:IVT_ENTRY(INT_KEYEVENT)]    ; es still at 0x0000
    mov ax, ds
    mov word [es:IVT_PTR_SEGMENT(old_kb_handler)], ax ; store the segment
    mov ax, si
    mov word [es:IVT_PTR_OFFSET(old_kb_handler)], ax ; store the offset
    call print_regs
    call print_newline
    lds si, [es:new_kb_handler]
    mov ax, ds
    mov word [es:IVT_ENTRY_SEGMENT(INT_KEYEVENT)], ax ; store the segment
    mov ax, si
    mov word [es:IVT_ENTRY_OFFSET(INT_KEYEVENT)], ax ; store the offset
    call print_regs
    call print_newline

    pop es
    pop ds
    call print_regs
    call print_newline
    
;    lds si, [new_kb_handler]
    mov ax, word [es:IVT_ENTRY_SEGMENT(INT_KEYEVENT)]   ; es still at 0x0000
    call print_hex_16
    mov al, ':'
    call print_char
    mov ax, word [es:IVT_ENTRY_OFFSET(INT_KEYEVENT)] ;
    call print_hex_16
    mov al, ' '
    call print_char

    mov ax, word [es:IVT_PTR_SEGMENT(old_kb_handler)]
    call print_hex_16
    mov al, ':'
    call print_char
    mov ax, word [es:IVT_PTR_OFFSET(old_kb_handler)]
    call print_hex_16
    mov al, ' '
    call print_char
    
    mov ax, word [es:IVT_PTR_SEGMENT(new_kb_handler)]
    call print_hex_16
    mov al, ':'
    call print_char
    mov ax, word [es:IVT_PTR_OFFSET(new_kb_handler)]
    call print_hex_16
    mov al, ' '
    call print_char
    
    call print_newline
    
    call reset_mouse  ;
    call print_hex_16 ;

    call print_newline
    
    mov ax, bx          ; number of mouse buttons
    call print_hex_16   ;
    
    call show_mouse     ; show the mouse
    
    xor ax, ax          ; set ax = 0
    sti                                             ; enable interrupts
.wtf:
    hlt
;    call print_regs
;    call print_newline
    inc ax
    jmp .wtf

    sti            ; Reenable hardware interrupts
.os_loop:
; TODO:  Add code to get disk information, check for bootable volumes, and transfer control to the boot volume
    hlt            ; Halt the processor and wait for hardware interrupts
    jmp .os_loop        ; Jump back up and halt the processor again

new_kb_handler:
    ;call dword [old_kb_handler]   ; call the old keyboard handler
;    call print_hex_16           ; print the scan code and character in hex
    inc bx
    iret                        ; return from the interrupt

; INT_VID_TTY_OUTPUT              0x0E    
;       AH = 0Eh
;       AL = character to write
;       BH = page number
;       BL = foreground color (graphics modes only)
print_char:
    push ax
    push bx
    mov ah, INT_VID_TTY_OUTPUT
    mov bx, 0x0007
    int INT_VID
    pop bx
    pop ax
    ret
    
; puts the cursor on a newline
print_newline:
    push ax
    push bx
    mov bx, 0x0007
    mov ah, INT_VID_TTY_OUTPUT
    mov al, 0x0a    ; CR
    int INT_VID
    mov al, 0x0d    ; LF
    int INT_VID
    pop bx
    pop ax
    ret

; ax = number to write to the screen
print_hex_16:
    push ax
    push bx
    push cx
    push dx
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
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; print all registers
print_regs:
    push ax             ; save ax
    call print_hex_16
    call print_space
    mov ax, bx
    call print_hex_16
    call print_space
    mov ax, cx
    call print_hex_16
    call print_space
    mov ax, dx
    call print_hex_16
    call print_space
    mov ax, sp
    call print_hex_16
    call print_space
    mov ax, bp
    call print_hex_16
    call print_space
    mov ax, si
    call print_hex_16
    call print_space
    mov ax, di
    call print_hex_16
    call print_space
    mov ax, ds
    call print_hex_16
    call print_space
    mov ax, es
    call print_hex_16
    call print_space
    popa                ; restore ax
    ret

print_colon:
    push ax
    push bx
    mov bx, 0x0007
    mov ax, INT_VID_TTY_OUTPUT
    mov al, ':'
    int INT_VID
    pop bx
    pop ax
    ret

print_space:
    push ax
    push bx
    mov bx, 0x0007
    mov ah, INT_VID_TTY_OUTPUT
    mov al, ' '
    int INT_VID
    pop bx
    pop ax
    ret

; Sets an interrupt vector
; mimics the old dos int 21h functionality:
; input ds:dx = addres of interrupt handling routine
set_interrupt_vector:
    push ds
    push es
    lds si, [es:IVT_ENTRY(INT_KEYEVENT)]    ; es still at 0x0000
    mov ax, ds
    mov word [es:IVT_PTR_SEGMENT(old_kb_handler)], ax ; store the segment
    mov ax, si
    mov word [es:IVT_PTR_OFFSET(old_kb_handler)], ax ; store the offset
    lds si, [es:new_kb_handler]
    mov ax, ds
    mov word [es:IVT_ENTRY_SEGMENT(INT_KEYEVENT)], ax ; store the segment
    mov ax, si
    mov word [es:IVT_ENTRY_OFFSET(INT_KEYEVENT)], ax ; store the offset
    pop es
    pop ds
    ret

; get an interrupt vector
; parameters:       bp+4 vector number
; return values:    bp+6 segment of interrupt vector
;                   bp+8 offset of interrupt vector
; returns an interrupt vector in the variable
; returns es:bx = interrupt vector
get_interrupt_vector:
    enter 0, 0
    push ax
    push ds
    push es
    xor ax, ax
    mov es, ax
    les bx, [es:IVT_ENTRY(INT_KEYEVENT)]    ; es still at 0x0000
    mov ax, ds
    mov word [es:IVT_PTR_SEGMENT(old_kb_handler)], ax ; store the segment
    mov ax, si
    mov word [es:IVT_PTR_OFFSET(old_kb_handler)], ax ; store the offset
    lds si, [es:new_kb_handler]
    mov ax, ds
    mov word [es:IVT_ENTRY_SEGMENT(INT_KEYEVENT)], ax ; store the segment
    mov ax, si
    mov word [es:IVT_ENTRY_OFFSET(INT_KEYEVENT)], ax ; store the offset
    pop es
    pop ds
    pop ax
    leave
    ret

save_interupt_vector:
    ret

; resets the mouse (call before calling any other mouse routine)
; returns ax = 0 if mouse is installed, -1 (0xffff) otherwise
;         bx = number of buttons
reset_mouse:
    mov ax, 0x0000
    int 0x33
    ret

; shows the mouse cursor
; returns nothing
show_mouse:
    mov ax, 0x0001
    int 0x33
    ret

old_kb_handler:         dd  0       ; far pointer used to store the original keyboard handler
pad_boot:
    times 510-($-$$)    db  0       ; Pad remainder of boot sector with 0s
                        dw  0xAA55  ; The standard PC boot signature

