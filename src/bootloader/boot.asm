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
  jmp main


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


main:
  ; setup data segments
  mov ax, 0         ; can't write to ds/es directly
  mov ds, ax
  mov es, ax

  ; setup stack
  mov ss, ax
  mov sp, 0x7C00    ; stack grows downwards (to smaller addresses)

  
  ; read something from floppy disk
  ; BIOS should set DL to drive number
  mov [ebr_drive_number], dl

  mov ax, 1         ; LBA=1, second sector from disk
  mov cl, 1         ; 1 sector to read
  mov bx, 0x7E00    ; data should be after the bootloader
  call disk_read


  ; print hello world message
  mov si, msg_hello
  call puts         ; calls puts function
  cli               ; disable interrupts, this way the CPU can't get out of 'halt' state
  hlt

;
; Error Handler
;


floppy_error:
  mov si, msg_read_failed
  call puts
  jmp wait_key_and_reboot

wait_key_and_reboot:
  mov ah, 0
  int 16h            ; waits for keypress
  jmp 0FFFFh:0       ; jumps to beginning of BIOS, which will reboot the system

.halt:
  cli                ; disable interrupts, this way the CPU can't get out of 'halt' state
  hlt
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
  

msg_hello:          db 'Hello world!', ENDL, 0
msg_read_failed:    db 'Read from disk failed!', ENDL, 0

times 510-($-$$) db 0
dw 0AA55h
