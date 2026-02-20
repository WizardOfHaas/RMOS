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

	;;STEP 3: Load Executables

	;;STEP 4: Event System
	;;		Make event handlers, tie them to IVTs

	;;;...then go back and add seg support to memory management
	;;		...and add useful flags to MM headers

	;mov si, keybd_isr
	;call print_regs

	;push event_table
	;call print_mem

	call init_mem
	call init_api

	;push test_file_name
	;call file_get_size

	push 0x256
	call malloc

	push si
	push _start_of_mem
	call ll_print
	pop si

	push test_file_name
	push si
	call file_load
	
	;call print_regs

	;;What do I need to do with segment registers here?
	;;pushad
	;push ds
	;push cs
	;mov ds, si
	;mov cs, si
	call si
	;;popad

task_loop:

	push test_msg
	call sprint

	;push 0x09
	;push test_isr
	;call register_ivt
end:
	jmp end

	int 0x20

test_msg: db "[DONE]", 10, 13, 0
test_file_name: db "progs/test.a", 0

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