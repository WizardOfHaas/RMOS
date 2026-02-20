    ;mov bp, sp
    ;mov cs, word [bp + 2]
main:
    mov ax, 1        ;;Print a message
    mov si, .msg
    int 30h

    xor ax, ax      ;;ABORT!
    int 30h

    .msg db "I'M INSIDE THE TEST TASK", 10, 13, 0
