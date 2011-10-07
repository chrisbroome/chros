	BITS 16

%define BIOS_START 		0x07c0
%define STACK_SPACE		0x1000
%define STACK_PARAGRAPH_OFFSET	(STACK_SPACE + 512) / 16

	jmp 0x0:start		; make this a far jump so that cs:ip is set
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
; TODO:  Add code to get disk information, check for bootable volumes, and transfer control to the boot volume
	hlt			; Halt the processor and wait for hardware interrupts
	jmp .os_loop		; Jump back up and halt the processor again

pad_boot:
	times 510-($-$$) db 0	; Pad remainder of boot sector with 0s
	dw 0xAA55		; The standard PC boot signature
