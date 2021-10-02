; example of how to call a function that calculates the lenght square of a 2D Vector
; using the CDECL convenctions
; given x, y, _lengthSq(x,y) = x * x + y * y

; F028		F02A		F02C
; ...		  ...		  ...
; sp 							 bp

	; save contents of eax, ecx, edx 
	push y
	push x
; F024		F026		F028		F02A		F02C
; 	x				y			...		  ...		  ...
;  sp							  							 bp

	call _lengthSq

	add sp, 4																; similar to pop x, y
																					; we move down the sp (register of top of the stack)
																					; this makes x, y free to be overwritten
; F024		F026		F028		F02A		F02C		; each register is separated by 2 bytes
; 	x				y			...		  ...		  ...
; 								sp 							 bp


_lengthSq:																; because we're using the small memory model type
																					; the return address offset is added to the stack
																					; this means that we're dealing with a near call

; F022		F024		F026		F028		F02A		F02			
; ret				x				y			...		  ...		  ...
; sp											  							 bp

																				  ; we need to store the 'original state' of the 
																					; function, so we push bp to where sp is
																					; and, when we return, we put it back where it was
	push bp
	mov bp, sp														  ; this is so common that there's a instruction called
																					; enter that does the same thing

; F020		F022		F024		F026		F028		F02A		F02			
; old bp  ret				x				y			...		  ...		  ...
;  sp											  							 
;  bp

	sub sp, 2																; allocating space for local variable r
																					; as the stack moves downward, subtracing = move up
; F01E		F020		F022		F024		F026		F028		F02A		F02			
; junk		old bp  ret				x				y			...		  ...		  ...
;  sp											  							 
;  				bp

	mov ax, [bp + 4]												; getting the value of x
																					; bp is our base, since is fixed we can get addresses
																					; relative to it

	mul ax																	; x * x
	mov [bp - 2], ax												; store value in local variable r
	mov ax, [bp + 6]												; getting the value of y
	mul ax																	; y * y
	add [bp - 2], ax												; r + y * y

; F01E		F020		F022		F024		F026		F028		F02A		F02			
; result  old bp  ret				x				y			...		  ...		  ...
;  sp											  							 
;  				bp

																					; now we need to return, with the proper convenction
																					; for integers, we return the value to the ax register
	mov ax, [bp - 2]

	mov sp, bp															; getting the stack back to its 'original state'
	pop bp																	; when we pop, sp moves upwards as well

; F01E		F020		F022		F024		F026		F028		F02A		F02			
; result  old bp  ret				x				y			...		  ...		  ...
;         			  sp 
;  																												bp	
	ret																			; returning from function

; F01E		F020		F022		F024		F026		F028		F02A		F02			
; result  old bp  ret				x				y			...		  ...		  ...
;         			 					 sp 
;  																												bp	
