org 0x7C00
bits 16

%define ENDL 0x0D, 0x0A     ; a simple macro to print end of line

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

  ; print hello world message
  mov si, msg_hello
  call puts         ; calls puts function

  hlt

.hlt:
  jmp .hlt

msg_hello: db 'Hello world!', ENDL, 0



times 510-($-$$) db 0
dw 0AA55h
