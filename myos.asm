%include "include/int_key.mac"
%include "include/int_vid.mac"

%define BIOS_START 		0x07c0
%define STACK_SPACE		0x1000
%define STACK_PARAGRAPH_OFFSET	(STACK_SPACE + 512) / 16
%define INTERRUPT_VECTOR_TABLE	0x0000 ; starts at 0x0000 ends at 0x03ff, 4 bytes per entry, provides argument for jmp instruction
%define IVT_ENTRY(n) (n << 2)

[BITS 16]

	jmp BIOS_START:0x0000+start	; make this a far jump so that cs:ip is set to 0x07c0:0x0000+start
start:
	cli			; Clear hardware interrupts
	xor ax, ax		; zero out ax
	mov es, ax		; Set the extra segment to the start of memory
	mov ax, BIOS_START	; The BIOS loads code here
	mov ds, ax		; Set data segment to where we're loaded
	add ax, STACK_PARAGRAPH_OFFSET ; (4096 + 512) / 16 bytes per paragraph
	mov ss, ax		; Set stack segment
	mov sp, STACK_SPACE	; Allocate stack space
	sti
.wtf
	hlt
	jmp .wtf
; code for setting up the keyboard handler

; interrupt 9 happens when any keyboard data is ready to be processed (key_up or key_down)
	mov bx, word [es:IVT_ENTRY(0x09)]	; read the segment part of the address, note cs = 0x0 from the first instruction
	mov word [old_kb_handler], bx ; store the segment
	mov bx, word [es:(IVT_ENTRY(0x09) + 2)]	; read the offset part of the address
	mov word [old_kb_handler + 2], bx ; store the offset 
; INT_VID_TTY_OUTPUT              0x0E    
;       AH = 0Eh
;       AL = character to write
;       BH = page number
;       BL = foreground color (graphics modes only)

	sti			; Reenable hardware interrupts
.os_loop:
; TODO:  Add code to get disk information, check for bootable volumes, and transfer control to the boot volume
	hlt			; Halt the processor and wait for hardware interrupts
	jmp .os_loop		; Jump back up and halt the processor again

new_kb_hanlder:
	;cli				; disable interrupts while processing this one
	call dword [old_kb_handler]	; call the old keyboard handler
;	mov ah, 0x10
;	int INT_KEY
	push ax
	push bx
	mov ah, INT_VID_TTY_OUTPUT
	mov bx, 0x0007
	int INT_VID
	pop bx
	pop ax
; code for our handler goes here
	;sti				; reenable interrupts
	iret				; return from the interrupt

print_char:
	

old_kb_handler:	dd	0	; pointer used to store the original keyboard handler
pad_boot:
	times 510-($-$$) db 0	; Pad remainder of boot sector with 0s
	dw 0xAA55		; The standard PC boot signature
