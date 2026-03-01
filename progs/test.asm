    ORG 0x000D      ;;This has to have a n ORG after the LL header
                    ;;  ...if I changed how headers were stored then I could remove this part

main:
    xor ax, ax      ;;ABORT!
    int 30h
    
    ;mov al, "A"
	;mov ah, 0x0E
	;mov bl, 0
	;int 0x10

    mov ax, 2       ;;Print a message
    mov si, .msg
    int 30h

    xor ax, ax      ;;ABORT!
    int 30h

    .msg db "I'M INSIDE THE TEST TASK", 10, 13, 0
