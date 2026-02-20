;Int to dec string
itoa:
    fn_enter
	fn_get_arg 1

    mov cx, 0
    mov bx, 10
    mov di, .t

.push:
    mov dx, 0
    div bx
    inc cx
    push dx
    test ax, ax
    jnz .push

.pop:
    pop dx
    add dl, '0'
    mov [di], dl
	inc di
    dec cx
    jnz .pop

    mov byte [di], 0
    
    mov si, .t
	fn_exit 1
	ret

    .t times 8 db 0

;Int to bin string
;	AL - integer to convert
;	SI - coverted string
btoa:
	pusha
	mov di, .t
	mov bl, 1
	xor cx, cx

.loop:
	mov byte [di], '0'
	inc cx
	test al, bl
	jz .next

	mov byte [di], '1'

.next:
	inc di
	shl bl, 1
	cmp cx, 8
	je .done
	jmp .loop	

.done:
	popa
	mov si, .t
	ret

	.t times 9 db 0

;Int to hex string
;	AL - integer to convert
;	SI - converted string
htoa:
	fn_enter
	fn_get_arg 1

   	push ax
	shr al, 4
   	cmp al, 10
	sbb al, 69h
   	das
 
	mov byte [.temp], al

   	pop ax
   	ror al, 4
   	shr al, 4
   	cmp al, 10
   	sbb al, 69h
   	das

   	mov byte [.temp + 1], al

   	mov ax, [.temp]
	fn_exit 1

   	ret

   .temp db 0, 0, 0

;Convert dec string to integer
;	SI - string to convert
;	AX - converted string's value
atoi:
   	pusha
	mov ax, si			
	call strlen

	add si, ax		
	dec si

	mov cx, ax		

	mov bx, 0		
	mov ax, 0

	mov word [.multiplier], 1	
.loop:
	mov ax, 0
	mov byte al, [si]		
	sub al, 48			

	mul word [.multiplier]		

	add bx, ax			

	push ax				
	mov word ax, [.multiplier]
	mov dx, 10
	mul dx
	mov word [.multiplier], ax
	pop ax

	dec cx				
	cmp cx, 0
	je .finish
	dec si				
	jmp .loop
.finish:
	mov word [.tmp], bx
	popa
	mov word ax, [.tmp]

	ret

	.multiplier	dw 0
	.tmp		dw 0

;Convert single char to int
;	AL - char to convert, this is dumb code...
ctoi:
	sub al, 48
	ret

;Get length of string
;	SI - string
;	AX - length of string
;strlen:
;	pusha
;
;	xor ax, ax
;.loop:
;	cmp byte [si], 0
;	je .done
;
;	inc si
;	inc ax
;	jmp .loop
;
;.done:
;	mov [.tmp], ax
;	popa
;	mov ax, [.tmp]
;	ret
;
;	.tmp: dw 0

;Get length of a string
;	SI - string
; Out
;	AX - length of string
strlen:
	push si

	xor ax, ax
.loop:
	cmp byte[si], 0
	je .done

	inc si
	inc ax
	jmp .loop

.done:
	pop si
	ret

;Compare SI and DI
;	Set carry on match
strcmp:
	pusha
.loop:
	mov al, byte [si]
	mov bl, byte [di]

	cmp al, bl
	jne .bad

	cmp al, 0
	je .done

	inc si
	inc di
	jmp .loop

.bad:
	popa
	clc
	ret

.done:
	popa
	stc
	ret