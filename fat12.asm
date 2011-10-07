; Sources:
; http://support.microsoft.com/kb/q140418/
;  
; Inside the FAT Boot Sector
; Because the MBR transfers CPU execution to the boot sector, the first few 
; bytes of the FAT boot sector must be valid executable instructions for an 
; 80x86 CPU. In practice these first instructions constitute a "jump" 
; instruction and occupy the first 3 bytes of the boot sector. This jump serves
; to skip over the next several bytes which are not "executable."
; 
; Following the jump instruction is an 8 byte "OEM ID". This is typically a 
; string of characters that identifies the operating system that formatted the 
; volume.
; 
; Following the OEM ID is a structure known as the BIOS Parameter Block, or 
; "BPB." Taken as a whole, the BPB provides enough information for the 
; executable portion of the boot sector to be able to locate the NTLDR file. 
; Because the BPB always starts at the same offset, standard parameters are 
; always in a known location. Because the first instruction in the boot sector 
; is a jump, the BPB can be extended in the future, provided new information is
; appended to the end. In such a case, the jump instruction would only need a 
; minor adjustment. Also, the actual executable code can be fairly generic. All
; the variability associated with running on disks of different sizes and 
; geometries is encapsulated in the BPB.
; 
; The BPB is stored in a packed (that is, unaligned) format. The following table
; lists the byte offset of each field in the BPB. A description of each field 
; follows the table. 
;
; Field               Offset Length
; -----               ------ ------
; Bytes Per Sector        11      2
; Sectors Per Cluster     13      1
; Reserved Sectors        14      2
; FATs                    16      1
; Root Entries            17      2
; Small Sectors           19      2
; Media Descriptor        21      1
; Sectors Per FAT         22      2
; Sectors Per Track       24      2
; Heads                   26      2
; Hidden Sectors          28      4
; Large Sectors           32      4
;
; Some additional fields follow the standard BIOS Parameter Block and constitute
; an "extended BIOS Parameter Block." The next fields are: 
; 
; Field                 Offset Length
; -----                 ------ ------
; Physical Drive Number     36      1
; Current Head              37      1
; Signature                 38      1
; ID                        39      4
; Volume Label              43     11
; System ID                 54      8
; 
; On a bootable volume, the area following the Extended BIOS Parameter Block is
; typically executable boot code. This code is responsible for performing 
; whatever actions are necessary to continue the boot-strap process. On Windows
; NT systems, this boot code will identify the location of the NTLDR file, load
; it into memory, and transfer execution to that file. Even on a non-bootable 
; floppy disk, there is executable code in this area. The code necessary to 
; print the familiar message, "Non-system disk or disk error" is found on most 
; standard, MS-DOS formatted floppy disks that were not formatted with the 
; "system" option.


[BITS 16]

bios_entry_point:
	jmp	short code_area	; jump to the code area after the control block in order to execute the loader
	nop			; "padding" the jump to 3 bytes as per the spec
oem_identifier:	db "BoxyFAT", 0	; the OEM identifer should be 8 bytes padded with zeroes

bpb:
.bytes_per_sector:	dw 1	; This is the size of a hardware sector and for most disks in use in the United
				; States, the value of this field will be 512.
.sectors_per_cluster:	db 1	; Because FAT is limited in the number of clusters (or "allocation units") that
				; it can track, large volumes are supported by increasing the number of sectors
				; per cluster. The cluster factor for a FAT volume is entirely dependent on the
				; size of the volume. Valid values for this field are 1, 2, 4, 8, 16, 32, 64, 
				; and 128. Query in the Microsoft Knowledge Base for the term "Default Cluster 
				; Size" for more information on this subject.
.reserved_sectors:	dw 1	; This represents the number of sectors preceding the start of the first FAT, 
				; including the boot sector itself. It should always have a value of at least 1.
.numbers_of_FATs:	db 1	; This is the number of copies of the FAT table stored on the disk. Typically, 
				; the value of this field is 2.
.root_entries:		dw 1	; This is the total number of file name entries that can be stored in the root 
				; directory of the volume. On a typical hard drive, the value of this field is 
				; 512. Note, however, that one entry is always used as a Volume Label, and that
				; files with long file names will use up multiple entries per file. This means 
				; the largest number of files in the root directory is typically 511, but that 
				; you will run out of entries before that if long file names are used.
.small_sectors:		dw 1	; This field is used to store the number of sectors on the disk if the size of
				; the volume is small enough. For larger volumes, this field has a value of 0, 
				; and we refer instead to the "Large Sectors" value which comes later.
.media_descriptor:	db 1	; This byte provides information about the media being used. The following table
				; lists some of the recognized media descriptor values and their associated 
				; media. Note that the media descriptor byte may be associated with more than 
				; one disk capacity.
				; Byte   Capacity   Media Size and Type
				;   F0    2.88 MB    3.5-inch, 2-sided, 36-sector
				;   F0    1.44 MB    3.5-inch, 2-sided, 18-sector
				;   F9     720 KB    3.5-inch, 2-sided, 9-sector
				;   F9     1.2 MB   5.25-inch, 2-sided, 15-sector
				;   FD     360 KB   5.25-inch, 2-sided, 9-sector
				;   FF     320 KB   5.25-inch, 2-sided, 8-sector
				;   FC     180 KB   5.25-inch, 1-sided, 9-sector
				;   FE     160 KB   5.25-inch, 1-sided, 8-sector
				;   F8   --------    Fixed disk
.sectors_per_FAT:	dw 1	; Part of the apparent disk geometry in use when the disk was formatted.
.sectors_per_track:	dw 1	; Part of the apparent disk geometry in use when the disk was formatted.
.hidden_sectors:	dd 1	; This is the number of sectors on the physical disk preceding the start of the 
				; volume. (that is, before the boot sector itself) It is used during the boot 
				; sequence in order to calculate the absolute offset to the root directory and
				; data areas.
.large_sectors:		dd 1	; If the Small Sectors field is zero, this field contains the total number of 
				; sectors used by the FAT volume.

ebpb:
.physical_drive_number:	db 1	; This is related to the BIOS physical drive number. Floppy drives are numbered 
				; starting with 0x00 for the A: drive, while physical hard disks are numbered 
				; starting with 0x80. Typically, you would set this value prior to issuing an 
				; INT 13 BIOS call in order to specify the device to access. The on-disk value
				; stored in this field is typically 0x00 for floppies and 0x80 for hard disks, 
				; regardless of how many physical disk drives exist, because the value is only 
				; relevant if the device is a boot device.
.current_head:		db 1	; This is another field typically used when doing INT13 BIOS calls. The value 
				; would originally have been used to store the track on which the boot record 
				; was located, but the value stored on disk is not currently used as such. 
				; Therefore, Windows NT uses this field to store two flags:
				; *	The low order bit is a "dirty" flag, used to indicate that autochk should
				; 	run chkdsk against the volume at boot time.
				; *	The second lowest bit is a flag indicating that a surface scan should 
				; 	also be run.
.signiture:		db 1	; The extended boot record signature must be either 0x28 or 0x29 in order to be
				; recognized by Windows NT.
.id:			dd 1	; The ID is a random serial number assigned at format time in order to aid in 
				; distinguishing one disk from another.
.volume_label:		db 11	; This field was used to store the volume label, but the volume label is now 
				; stored as a special file in the root directory.
.system_id:		db 8	; This field is either "FAT12" or "FAT16," depending on the format of the disk.

code_area:			; This is where the code for our boot sector should go
; TODO: put relavent boot code here 
	times 510-($-$$) db 0	; Pad remainder of boot sector with 0s
	dw 0xAA55		; The standard PC boot signature

