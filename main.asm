	org 0x100

	jmp short start	;Jump to startup

	db 'main.asm'

start:
	mov ax, 0x1000
	mov ss, ax

	;xor ax, ax
	;mov ds, ax

	;;STEP 1: Change to stack calling convention
	;;		I probably need a macro to flip/unwind the stack
	
	;;STEP 2: New malloc/free
	;;		Doubly linked list with headers for last, next, status, size

	;;STEP 3: Load Executables <---I AM HERE

	;;STEP 4: Event System
	;;		Make event handlers, tie them to IVTs

	;mov si, keybd_isr
	;call print_regs

	;push event_table
	;call print_mem

	call init_mem	
	call init_api

	;push test_file_name
	;call file_get_size

	call malloc

	;;Lets load a test program
	push es
	push si
	push test_file_name
	push si
	call file_load
	pop si
	pop es

	;;Prove it
	push es
	push si
	call print_mem

	;;Run it
	pushad
	mov word [prog_ptr], es
	mov word [prog_ptr + 2], si

	push es						;;Push es for the task to pick up
	jmp far [prog_ptr] 			;;This is annoying... is there a better way?
task_loop:
	popad

	push test_msg
	call sprint

end:
	jmp end

	int 0x20

test_msg: db "[DONE]", 10, 13, 0
test_file_name: db "progs/test.a", 0
prog_ptr: dw 0

%macro fn_enter 0
	push bp
	mov bp, sp
%endmacro

%macro fn_get_arg 1-2 ax
	mov %2, [bp + 2 + 2 * %1]
%endmacro

%macro fn_exit 0-1 0
	pop bp
	ret 2 * %1
%endmacro

%include "./lib/tty.asm"
%include "./lib/string.asm"
%include "./lib/mem.asm"
%include "./lib/ivt.asm"
%include "./lib/file.asm"
%include "./lib/api.asm"

times 64 db 0

_start_of_mem: