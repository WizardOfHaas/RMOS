struc event
    .off: resw 1
    .seg: resw 1
    .int: resb 1
endstruc

%macro isr_stub 1
    pushad
    push %1
    call find_event

    cmp si, 0
    je .done

    call si

.done:
    popad
    iret
%endmacro

event_table: 
    ;;Entry 1: for keyboard ISR
    dw keybd_isr   ;;off
    dw 0x0192      ;;seg
    db 0x09        ;;int
    db 00          ;;terminate

find_event:
    fn_enter
    fn_get_arg 1, ax

    mov si, event_table
.loop:
    cmp byte [si + event.int], al
    je .done

    add si, event
    cmp byte [si], 0    ;;Is this a termination?
    je .miss

    jmp .loop

.miss:
    xor si, si

.done:
    mov es, word [si + event.seg]
    mov si, word [si + event.off]
    fn_exit 1

register_ivt:
    fn_enter

    fn_get_arg 1, si    ;;Handler address
    fn_get_arg 2, bx    ;;Interrupt number

    ;;Calculate location for IVT entry
    mov ax, 4       ;;Entries a 4 bytes, so load up AX for a mul
    mul bx          ;;Multipy by BX, the interrupt number
    mov di, ax      ;;Set DI as our destination

    cli                     ;;Turn off interrupts
    push es                 ;;Preserve DS
    xor ax, ax              ;;Set DS=0 for the mov
    mov es, ax

    mov word es:[di], si       ;;Set pointer to handler
    mov word es:[di + 2], cs   ;:Set segment

    pop es                  ;;Preserve DS
    sti                     ;;Turn on interrupts

    fn_exit 2

keybd_isr:
    pushad
    in al, 0x60     ;;Get a keystroke
    push ax
    call hprint
    mov al, 0x20
    out 0x20, al
    popad
    iret

test_isr:
    isr_stub 0x09