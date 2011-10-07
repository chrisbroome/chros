%include "include/int_key.mac"
%include "include/int_vid.mac"
%include "include/mbr.asm"

	BITS 16

%define BIOS_START 		0x07c0
%define STACK_SPACE		0x1000
%define STACK_PARAGRAPH_OFFSET	(STACK_SPACE + 512) / 16

	jmp 0x0:start		; make sure this is a far jump to set cs:ip
start:
	cli			; Clear hardware interrupts
	mov ax, BIOS_START	; The BIOS loads code here
	mov ds, ax		; Set data segment to where we're loaded
	mov es, ax		; Set extra segment to where we're loaded
	add ax, STACK_PARAGRAPH_OFFSET ; (4096 + 512) / 16 bytes per paragraph
	mov ss, ax		; Set stack segment
	mov sp, STACK_SPACE	; Allocate stack space
	sti			; Reenable hardware interrupts
.os_loop:
	cli			; Clear interrupts
	hlt			; Halt the processor and wait for hardware interrupts
	jmp .os_loop		; Jump back up and halt the processor again

; This section
	times 440-($-$$) db 0   ; Pad the remainder up to the disk signiture
disk_sig:
	dd 0x00000000		; disk signiture of the mbr (just set to 0s here)
nulls:
	dw 0x0000               ; nulls (again, just 0s)
part_tab_1:
part_tab_2:
part_tab_3:
part_tab_4:
pad_boot:
	dw 0xAA55		; The standard PC boot signature
