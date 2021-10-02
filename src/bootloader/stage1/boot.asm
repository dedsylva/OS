org 0x7C00
bits 16

%define ENDL 0x0D, 0x0A     ; a simple macro to print end of line

;
; FAT12 headers 
;

jmp short start           ;(first 3 bytes must be short jump instruction followed by a no op)
nop

; OEM identifier (8 bytes string identifying the version of DOS used)
bdb_oem:                    db 'MSWIN4.1'      ; 8 bytes
bdb_bytes_per_sector:       dw 512             ; size of 512 kB
bdb_sectors_per_cluster:    db 1
bdb_reserved_sectors:       dw 1
bdb_fat_count:              db 2
bdb_dir_entries_count:      dw 0E0h
bdb_total_sectors:          dw 2880            ; 2880 * 512 = 1.44 MB
bdb_media_descriptor_type:  db 0F0h            ; 3.5 inches floppy disk
bdb_sectors_per_fat:        dw 9               ; 9 sectors/fat
bdb_sectors_per_track:      dw 18
bdb_heads:                  dw 2
bdb_hidden_sectors:         dd 0
bdb_large_sector_count:     dd 0

; extended boot record
ebr_drive_number:           db 0
                            db 0
ebr_signature:              db 29h
ebr_volume_id:		    db 12h, 34h, 56h, 78h
ebr_volume_label:           db 'DEDS OS    '    ; 11 bytes padded with spaces
ebr_system_id:              db 'FAT12   '       ; 8 bytes padded with spaces


;
; Code Goes here
;


; Stating that main is where the program starts
start:
 ; setup data segments
  mov ax, 0         ; can't write to ds/es directly
  mov ds, ax
  mov es, ax

  ; setup stack
  mov ss, ax
  mov sp, 0x7C00    ; stack grows downwards (to smaller addresses)

	; making sure the code segment is zero, somme BIOS may initiate bootloader with 0x7C00
	push es
	push word .after
	retf

.after:
  
  ; read something from floppy disk
  ; BIOS should set DL to drive number
  mov [ebr_drive_number], dl

  ; show loading image
	mov si, msg_loading 
  call puts         													; calls puts function

	; read drive parameters (sectors per track and head count),
	; instead of relying on data on formatted disk (BIOS is safer)
	push es
	mov ah, 08h
	int 13h 				 														; caling interrupt 13h BIOS function
	jc floppy_error
	pop es

	and cl, 0x3F																; remove top 2 bits
	xor ch, ch
	mov [bdb_sectors_per_track], cx							; head count
	
	inc dh
	mov [bdb_heads], dh

	; read FAT root directory
	mov ax, [bdb_sectors_per_fat]								; compute LBA of root = reserver + fat * sec_per_fat
	mov bl, [bdb_fat_count]
	xor bh, bh
	mul bx																			; ax = (fats * sectors_per_fat)
	add ax, [bdb_reserved_sectors]							; ax = LBA of root directory
	push ax


	; compute size of root directory = (32 * number_of_entries) / bytes_per_sector
	mov ax, [bdb_dir_entries_count]
	shl ax, 5																		; ax *= 32
	xor dx, dx 																	; dx = 0
	div word [bdb_bytes_per_sector]							; number of sectors we need to read

	test dx, dx																	; if dx != 0, add 1
	jz .root_dir_after
	inc ax

																							; division remainder != 0, add 1
																							; this means we have a sector only partially
																							; filled dwith entries

.root_dir_after:
	; read root directory
	mov cl, al																	; cl = number of sectors to read = size of root
	pop ax																			; ax = LBA of directory
	mov dl, [ebr_drive_number]									; dl = drive number (saved it previously)
	mov bx, buffer															; es:bx = buffer
	call disk_read

	; search for kernel.bin in the directory entries
	xor bx, bx
	mov di, buffer															; name of file is the first entry

.search_kernel:
	mov si, file_kernel_bin
	mov cx, 11																	; lentgh of name of the file (11 bytes)
	push di
	repe cmpsb																	; compsb: compare two bytes (we can compare string)
																							; one byte in ds:si and the other in es:di
																							; si and di are incremented (direction flag = 0)
																							; or decremented (direction flat = 1)

																							; repe: repeat while equal
																							; it will repeat the compare instruction as long
																							; as they are equal up to cx times, while decreasing
																							; cx (which is 11 in this case)

	pop di 																			; restore di to its original value
	je .found_kernel														; jump if condition is met
	
	add di, 32																	; if it didnt found, moves to the next directory
																							; entry (which has 32 bytes of length)

	inc bx																			; increment how many entries we checked
	cmp bx, [bdb_dir_entries_count]							; check if we checked all of them already
	jl .search_kernel														; if we didn't finish, goes back in loop

	; kernel not found, we checked every entry
	jmp kernel_not_found_error



.found_kernel:

	; di should have the address to the entry
	mov ax, [di + 26]														; first logical cluster field (offset 26)
	mov [stage2_cluster], ax

	; read file allocation tablel (load FAT from disk into memory)
	mov ax, [bdb_reserved_sectors]
	mov bx, buffer
	mov cl, [bdb_sectors_per_fat]
	mov dl, [ebr_drive_number]
	call disk_read

	; the area with the most memory we can put the file content is
	; between 0x7E00 and 0x7FFFF (called the Conventional Memory)
	; REMEMBER: WE ARE CURRENTLY WORKING WITH ONLY 16-BITS view mode ,
	; this means we can only access up to 1MB of memory (THE LOW MEMORY REGION)
		
	; read the file annd the process chain (read kernel)
	mov bx, KERNEL_LOAD_SEGMENT
	mov es, bx
	mov bx, KERNEL_LOAD_OFFSET

.load_kernel_loop:
	; Read next cluster
	mov ax, [stage2_cluster]
	add ax, 31																	; frst_clus = (clu-2)*sectors_per_clu + start_sector
																							; start_sector = reserv + fat + root size

	mov cl, 1
	mov dl, [ebr_drive_number]
	call disk_read

	add bx, [bdb_bytes_per_sector]

	; compute location of next cluster
	mov ax, [stage2_cluster]
	mov cx, 3
	mul cx
	mov cx, 2
	div cx																			; ax = index of entry in FAT, dx = cluster mod 2

	mov si, buffer
	add si, ax
	mov ax, [ds:si]															; read entry from FAT table at index ax

	or dx, dx
	jz .even

.odd:
	shr ax, 4
	jmp .next_cluster_after

.even:
	and ax, 0x0FFF

.next_cluster_after:
	cmp ax, 0x0FF8															; check if reache EOF
	jae .read_finish

	mov [stage2_cluster], ax
	jmp .load_kernel_loop

.read_finish:

	; jump to our kernel
	mov dl, [ebr_drive_number]									; boot device in dl
	
	mov ax, KERNEL_LOAD_SEGMENT									; set segment registers
	mov ds, ax
	mov es, ax

	jmp KERNEL_LOAD_SEGMENT:KERNEL_LOAD_OFFSET

	jmp wait_key_and_reboot											; should never happen




	



  cli               													; disable interrupts, this way the CPU 
  hlt																					; can't get out of 'halt' state


;
; Error Handler
;


floppy_error:
  mov si, msg_read_failed
  call puts
  jmp wait_key_and_reboot

kernel_not_found_error:
	mov si, msg_stage2_not_found
	call puts
	jmp wait_key_and_reboot


wait_key_and_reboot:
  mov ah, 0
  int 16h            ; waits for keypress
  jmp 0FFFFh:0       ; jumps to beginning of BIOS, which will reboot the system

.halt:
  cli                ; disable interrupts, this way the CPU can't get out of 'halt' state
  hlt


; Prints characters untill it finds the NULL character
; Params: (pointer to string in ds:si)
;       - ds:si
puts:
  ; push the registers that will be modified to the stack
  push si
  push ax
  push bx

; enters the main loop
.loop:
  lodsb           ; lodsb instruction loads the byte from ds:si into al register
                  ; incrementing si
  or al, al       ; verify if next character is null (modifies flag register if is zero)
  jz .done        ; jz: jumps to destination if zero flag is set

  mov ah, 0x0E    ; calls bios interrupt
  mov bh, 0       ; set page number to 0 (required for this bios function)
  int 0x10        ; sets the interrupt signal 

  jmp .loop   ; otherwise continues the loop

.done:
  ; pop registers previously pushed in reversed order
  ; returns
  pop bx
  pop ax
  pop si
  ret





;
; Disk Routines
;


;
; Converts an LBA address to a CHS address
; Parameters:
;   - ax: LBA address
; Returns:
;   - cx [bits 0-5]: sector number -- cl 
;   - cx [bits 6-15]: cylinder -- remainder of cl and ch
;   - dh: head
;

lba_to_chs:
  push ax                                     ; save ax by pushing it to the stack
  push dx                                     ; save dx by pushing it to the stack

  xor dx, dx                                  ; we need to clear dx = 0 because div divides dx:ax
  ; div: result in ax, remainder in dx
  div word [bdb_sectors_per_track]            ; ax = LBA / SectorsPerTrack
  
  inc dx                                      ; dx = sextor = (LBA % SectorsPerTrack + 1) 
  mov cx, dx                                  ; cx = sector
  
  xor dx, dx                                  ; dx = 0
  div word [bdb_heads]                        ; ax = Cylinder = (LBA/SectorsPerTrack) / Heads
                                              ; dx = Head = (LBA/SectorsPerTrack) % Heads
  
  mov dh, dl                                  ; dh = head (dl is lower 8bit of dx, dh is the higher)
  
                                              ; CX =        ---CH---  ---CL---
                                              ; Cylinder:   76543210  98
                                              ; Sector:                 543210
  mov ch, al                                  ; ch = cylinder (lower 8 bits of ax)
  shl ah, 6                                   ; shift upper 2 bits to the left by 6 positions
  or cl, ah                                   ; put upper 2 bits of cylinder in CL

  ; we can't push/pop 8-bit registers to the stack
  pop ax                                      ; ax = dx 
  mov dl, al                                  ; restore dl to its original value
  pop ax                                      ; restore ax (ax = ax)
  ret                                         ; return


;
; Reads sectors from a disk
; Parameters:
;   - ax: LBA address
;   - cl: number of sectors to read (up to 128)
;   - dl: drive number
;   - es:bx: memory address where to store read data
;
disk_read:

  push ax                                     ; save registers we will modify
  push bx
  push cx
  push dx
  push di

  push cx
  call lba_to_chs                             ; compute CHS from LBA
  pop ax                                      ; ax = cx in the stack

  mov ah, 02h                                 ; ah = 2 hexadecimal
  mov di, 3                                   ; number of tries we will make to read disk

.retry:
  pusha                                       ; BIOS may overwrite some reigsters, so we store all
                                              ; just in case
  stc                                         ; set carry flag, some BIOS don't set it
  int 13h                                     ; carry flag cleared = success, end of loop
  jnc .done                                   ; jnc = jumps if carry flag = 0

  ; if read failed
  popa
  call disk_reset

  dec di                                      ; di = di - 1
  test di, di                                 ; test if di = di
  jnz .retry                                  ; jnz = jump if zero-flag is not set 

.fail:
  jmp floppy_error                            ; all attempts failed

.done:
  popa                                        ; restore the registers

  pop di                                     ; restore registers modified
  pop dx
  pop cx
  pop bx
  pop ax
  ret                                         ; the return expects the address to be at the 
                                              ; top of the stack

;
; Resets disk Controller
; Parameters:
;   - dl: drive number
;
disk_reset:
  pusha
  mov ah, 0
  stc  
  int 13h
  jc floppy_error                             ; jumps if carry set
  popa
  ret                                         ; the return expects the address to be at the 
                                              ; top of the stack
  

msg_loading:          db 'Loading...', ENDL, 0
msg_read_failed:   		db 'Read from disk failed!', ENDL, 0
msg_stage2_not_found:	db 'STAGE2.BIN file not found!', ENDL, 0
file_kernel_bin:			db 'STAGE2   BIN'
stage2_cluster:				dw 0

KERNEL_LOAD_SEGMENT		equ 0x2000							; the equ directive doesn't allocate memory
KERNEL_LOAD_OFFSET		equ 0										; for the constants (equivalent to #define in c)

times 510-($-$$) db 0
dw 0AA55h

buffer:
