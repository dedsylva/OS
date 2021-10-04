bits 16

section _TEXT class=CODE							; tells assembly which section to run our code

;
; void _cdecl x86_div64_32(uint64_t dividend, uint32_t divisor, uint64_t* quotientOut, uint32_t* remainderOut);
;
global _x86_div64_32
_x86_div64_32:
	; make new call state
	push bp														; save old state
	mov bp, sp 												; initialize new state

	push bx

	; divide upper 32 bits
	mov eax, [bp + 8]									; eax <- upper 32 bits of dividend
	mov ecx, [bp + 12]								; ecx <- divisor
	xor edx, edx
	div ecx														; eax - quot, edx - remainder
	
	; store upper 32 bits of quotient
	mov bx, [bp + 16]
	mov [bx + 4], eax

	; divide lower 32 bits
	mov eax, [bp + 4]									; eax <- lower 32 bits of dividend
																		; edx <- old remainder
	div ecx

	; store results
	mov [bx], eax
	mov bx, [bp + 18]
	mov [bx], edx

	pop bx

	; restore old state
	mov sp, bp
	pop bp
	ret


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
