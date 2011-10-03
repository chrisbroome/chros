%include "include/int_key.mac"
%include "include/int_vid.mac"

	BITS 16

%define BIOS_START 		0x07c0
%define STACK_SPACE		0x1000
%define STACK_PARAGRAPH_OFFSET	(STACK_SPACE + 512) / 16

	jmp start
start:
	cli			; Clear hardware interrupts
	mov ax, BIOS_START	; The BIOS loads code here
	mov ds, ax		; Set data segment to where we're loaded
	;mov cs, ax		; Set code segment to where we're loaded
	mov es, ax		; Set extra segment to where we're loaded
	add ax, STACK_PARAGRAPH_OFFSET ; (4096 + 512) / 16 bytes per paragraph
	mov ss, ax		; Set stack segment
	mov sp, STACK_SPACE	; Allocate stack space
	sti			; Reenable hardware interrupts
.os_loop:
	hlt			; Halt the processor and wait for hardware interrupts
	jmp .os_loop		; Jump back up and halt the processor again


read_character_start:
	xor ax, ax		; zero out ax
	mov bx, 0007h		; used when writing characters.  page = 0, color = 7
	mov cx, 0001h		; used when writing characters.  only output 1 character at a time
.read_character:
	mov ah, INT_KEY_READ_KEY; BIOS routine to read a character from the keyboard
	int INT_KEY		; call the keyboard communication routine
                                ; ah contains the scancode, al contains the character
.write_charcter_to_screen:
	mov ah, INT_VID_PUT_CHAR; will be calling function 09h, put a character to the screen
	int INT_VID		; call the video interrupt
	jmp .read_character	; instead of using CPU cycles at idle, wait for keyboard input


print_string:			; Routine: output string in SI to screen
	mov ah, INT_VID_PUT_STRING	; int 10h 'print char' function
.repeat:
	lodsb			; Get character from string
	cmp al, 0		;
	je .done		; If char is zero, end of string
	int INT_VID		; Otherwise, print it
	jmp .repeat		;
.done:
	ret

pad_boot:
	times 510-($-$$) db 0	; Pad remainder of boot sector with 0s
	dw 0xAA55		; The standard PC boot signature
