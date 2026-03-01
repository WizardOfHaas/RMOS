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

;;Different calling convention since this is a direct interrupt handler
;;  ...maybe I can change that?
;;  I'm going to wrap API calls in macros so... I can hide w/e I want!
;;AX - service number
api_handler:
    pushad

    call print_regs

    cmp ax, MAX_SERVICE_NUMBER
    jg .done

    ;;Grab the service handler from our table
    push ax
    push bx
    mov di, _api_service_handler_table
    mov bx, 2
    mul bx
    add di, ax
    pop bx
    pop ax

    call [di]

.done:
    popad
    iret

_api_service_handler_table:
    dw _abort_handler
    dw _print_regs_handler
    dw _sprint_handler

_abort_handler:     ;;00
    popad
    add sp, 6       ;;Clear stack
    jmp task_loop   ;;Re-enter the kernel

_print_regs_handler:;;01
    call print_regs
    ret

_sprint_handler:    ;;02
    push si
    call sprint
    ret