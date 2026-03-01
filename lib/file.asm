    db 'file.asm'

;;I'm doing a dumb stub to start with
;;  This is going to use the DOS API to load files
;;  LATER I'll add my own FAT-12 driver

;Load a file
;Args: file path, address to load contents
file_load:
    fn_enter

    fn_get_arg 2, dx    ;;File Path

    mov ah, 0x3d
	mov al, 0
	int 0x21
	jc .file_err

    fn_get_arg 1, dx    ;;Target address(aka FILE BUFFER)

    push ds
    push es
    pop ds
	mov bx, ax          ;;Set file handle
	mov ah, 0x3F		;;We are going to read the file
	mov cx, 1024
	int 0x21
    pop ds
	jc .file_err

    fn_exit 2

.file_err:
    push .err_msg
    call sprint
    fn_exit 2

.err_msg: db 'file fucked', 0

file_get_size:
    fn_enter
    fn_get_arg 1, dx
    mov ah, 0x4E
    mov al, 0x78
    int 0x21
    call print_regs
    fn_exit 1