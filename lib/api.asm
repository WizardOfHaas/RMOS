    db "api.asm"

;;This defines our API for external programs
%define MAX_SERVICE_NUMBER 2

;Register our main interrupt: 30h
init_api:
    fn_enter
    push 30h
    push api_handler
    call register_ivt
    fn_exit

;;AX - service number
api_handler:
    pushad

    cmp ax, MAX_SERVICE_NUMBER
    jg .done

    mov di, _api_service_handler_table
    mov bx, 2
    mul bx
    add di, ax ;;Is this getting the correct address?

    call print_regs

    call di

.done:
    popad
    iret

    .msg db '[API TEST]', 10, 13, 0

_api_service_handler_table:
    dw _abort_handler
    dw _print_regs_handler
    dw _sprint_handler

_abort_handler:
    popad
    add sp, 6       ;;Clear stack
    jmp task_loop   ;;Re-enter the kernel

_print_regs_handler:
    call print_regs
    ret

_sprint_handler:
    push si
    call sprint
    ret