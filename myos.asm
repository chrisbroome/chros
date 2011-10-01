	BITS 16

start:
	mov ax, 07C0h		; Set up 4K stack space after this bootloader
	add ax, 288		; (4096 + 512) / 16 bytes per paragraph
	mov ss, ax
	mov sp, 4096

	mov ax, 07C0h		; Set data segment to where we're loaded
	mov ds, ax

	mov bx, 0007h		; used when writing characters.  page = 0, color = 7
	mov cx, 0001h		; used when writing characters.  only output 1 character at a time
.read_character:
	mov ah, 00h		; read a character from the keyboard
	int 16h			; call the keyboard communication routine
                                ; ah contains the scancode, al contains the character
.write_charcter_to_screen:
	mov ah, 09h		; will be calling function 09h, put a character to the screen
	int 10h			; call the video interrupt
	jmp .read_character	; instead of using CPU cycles at idle, wait for keyboard input

print_string:			; Routine: output string in SI to screen
	mov ah, 0Eh		; int 10h 'print char' function

.repeat:
	lodsb			; Get character from string
	cmp al, 0
	je .done		; If char is zero, end of string
	int 10h			; Otherwise, print it
	jmp .repeat

.done:
	ret

	times 510-($-$$) db 0	; Pad remainder of boot sector with 0s
	dw 0xAA55		; The standard PC boot signature
