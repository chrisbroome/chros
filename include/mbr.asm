%ifndef MBR_ASM
%define MBR_ASM

struc	chs_address
	.heads:			resb	1
	.cylinder98_sector:	resb	1
	.cylinder70:		resb	1
endstruc

struc	mbr_partition_record
	.boot_status:		resb	1
	.abs_first_sector:	resb	chs_address_size
	.partition_type:	resb	1
	.abs_last_sector:	resb	chs_address_size
	.logical_block_address:	resd	1
	.total_sectors:		resd	1
endstruc

struc	master_boot_record
	.code:			resb	440
	.disk_signiture:	resd	1
	.magic_word:		resw	1
	.primary_partition_table:	resb	mbr_partition_record_size*4
	.mbr_signiture:		resw	1
endstr

%endif
