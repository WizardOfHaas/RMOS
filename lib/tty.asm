	db 'tty.asm'

;Args: character to print
cprint:
	fn_enter
	push ax
	push bx

	fn_get_arg 1
	mov ah, 0x0E
	mov bl, 0
	int 0x10

	pop bx
	pop ax
	fn_exit 1
    ret

sprint:
	fn_enter
	fn_get_arg 1

	push si
	mov si, ax
.loop:
	mov al, ds:[si]
	cmp al, 0
	je .done

	push ax
	call cprint
	inc si
	jmp .loop
.done:
	pop si
	fn_exit 1
	ret

newline:
	fn_enter
	push 10
	call cprint
	push 13
	call cprint
	fn_exit

print_regs:
	fn_enter
	pusha

	;Push regs to display to stack
	push cs
	push ds
	push bp
	push sp
	push fs
	push es
	push di
	push si
	push dx
	push cx
	push bx
	push ax

	mov si, .labels
.loop:
	push si
	call sprint

	call hprint

	add si, 5
	cmp si, .labels + 5 * 12
	jl .loop

	call newline

	popa
	fn_exit 0

	.labels:
		db ' AX:', 0
		db ' BX:', 0
		db ' CX:', 0
		db ' DX:', 0
		db ' SI:', 0
		db ' DI:', 0
		db ' ES:', 0
		db ' FS:', 0
		db ' SP:', 0
		db ' BP:', 0
		db ' DS:', 0
		db ' CS:', 0

;Print stack
print_stack:
	fn_enter

	push "<"
	call cprint

	push ss
	call hprint

	push ":"
	call cprint

	push sp
	call hprint
	
	push ">"
	call cprint

	mov si, sp	;;Start at SP
	add si, 4	;Skip this functions entry
	xor cx, cx
.loop:
	push word ss:[si]
	call hprint
	
	push " "
	call cprint

	add si, 2
	inc cx
	cmp cx, 10
	jle .loop

	call newline

	fn_exit

;Print memory at location
print_mem:
	fn_enter

	push si

	fn_get_arg 2
	push ax
	call hprint

	fn_get_arg 1

	push ":"
	call cprint

	push ax
	call hprint

	push "|"
	call cprint

	mov si, ax
	mov cx, ax
	add cx, 16
.hex_loop:
	push word es:[si]
	call hprint
	
	push " "
	call cprint

	add si, 2
	cmp si, cx
	jle .hex_loop

	;Now do the same thing for character display
	fn_get_arg 1
	
	push "|"
	call cprint

	mov si, ax
	mov cx, ax
	add cx, 16

.char_loop:
	push word es:[si]
	call cprint

	add si, 1
	cmp si, cx
	jle .char_loop

	call newline

	pop si

	fn_exit 2

;Print an integer to the screen in hex (word)
hprint:
	fn_enter
	push ax

	;;First, print AH
	fn_get_arg 1
	mov al, ah	;The lower half of the arg gets htoa'd, so swap it in
	push ax		;Set arg for htoa
	call htoa

	push ax		;AX is now the char representation of AL, save it
	push ax		;Set arg for cprint
	call cprint	;Print first char
	
	pop ax		;Retrieve the char
	mov al, ah	;Swap to print next char
	push ax		;Push arg
	call cprint	;Print it!

	;;Second, print AL
	fn_get_arg 1
	push ax		
	call htoa

	push ax
	push ax
	call cprint
	
	pop ax
	mov al, ah
	push ax
	call cprint

	pop ax
	fn_exit 1