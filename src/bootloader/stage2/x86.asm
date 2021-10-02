bits 16

section _TEXT class=CODE							; tells assembly which section to run our code

;
; int 10h ah=0Eh (the interrupt 10 hexadecimal function prints character in screen)
; args: character, page
;

global _x86_Video_WriteCharTeletype
_x86_Video_WriteCharTeletype:
	; make new call state
	push bp														; save old state
	mov bp, sp 												; initialize new state

	; save bx
	push bx
	; [bp + 0] - old state 
	; [bp + 2] - return address (small memory model => 2 bytes)
	; [bp + 4] - first argument (character); bytes to words (can't push single bytes to stack)
	; [bp + 6] - second argument (page)
	mov ah, 0Eh
	mov al, [bp + 4]
	mov bh, [bp + 6]

	int 10h

	; restore bx
	pop bx

	; restore old state
	mov sp, bp
	pop bp
	ret
