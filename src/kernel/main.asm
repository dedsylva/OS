org 0x0 
bits 16

%define ENDL 0x0D, 0x0A     ; a simple macro to print end of line

; Stating that main is where the program starts
start:
  jmp main


main:
  ; print hello world message
  mov si, msg_hello
  call puts         ; calls puts function


.halt:
	cli
	hlt

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


msg_hello: db 'Hello world from KERNEL!', ENDL, 0
