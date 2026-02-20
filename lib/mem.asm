    db 'mem.asm'

%define REGION_USED "U"

struc ll_node
    .prev: resw 2
    .next: resw 2
    .size: resw 2
    .flags: resb 1 
endstruc

%macro make_ll_node 3-5 0, 0
    mov word [%1 + ll_node.prev], %2
    mov word [%1 + ll_node.next], %3
    mov word [%1 + ll_node.size], %4
    mov byte [%1 + ll_node.flags], %5
%endmacro

%define get_node_size(a) word [a + ll_node.size]
%define get_node_next(a) word [a + ll_node.next]
%define get_node_prev(a) word [a + ll_node.prev]

%define set_node_prev(a, b) mov word [a + ll_node.prev], b

;;What I need:
;; - Init linked list
;;      struct?
;;  - Add entry to linked list
;;  - Remove entry from linked list
;;  - Find free chunk
;;  - Split chunk
;;  - Mark chunk as used
;;  - Mark chunk as free
;;  - Merge free chunks?
;;  - Expand for mutliple segments
;;      For that I could have an initial LL entry for each seg
;;      And just expand ll_node struct to store seg data

;Initialize memroy manager
;This takes no args right now, just points at the end of the program and GOES!
init_mem:
    fn_enter

    ;I just need to make the start of mem into an ll node
    make_ll_node _start_of_mem, 0, 0, 0xFFFF - _start_of_mem - ll_node

    fn_exit

;Splits off a chunk of a node
;Args - node to split, size of new node
;Ret - SI, address to new node
split_region:
    fn_enter

    fn_get_arg 2    ;;Node to split
    mov si, ax

    fn_get_arg 1    ;;Size of new node

    ;TODO: Check the node has enouhg space... this should be a PANIC

    ;Calculate start of new chunk (end of region - header - new_size)
    mov di, si                       ;;DI will be the Destination of the new block
    add di, get_node_size(si)        ;;Skip to end of region
    sub di, ll_node_size             ;;Subtract header size
    sub di, ax                       ;;Subtract new region size

    push di                          ;;Save for return

    ;;[DI now points to new header location]

    ;;Get the pointer to NEXT from the split node
    mov bx, get_node_next(si)

    ;Make new LL header
    make_ll_node di, si, bx, ax

    ;;Now we adjust our neighbors
    cmp bx, 0   ;;Did the pslit node have a NEXT?
    je .no_next

    ;;If the split node had a NEXT then I need to get the NEXT's PREV
    set_node_prev(bx, di)

.no_next:
    sub word [si + ll_node.size], ax    ;Update existing LL header size

    
    mov word [si + ll_node.next], di    ;Set split block to point to new block


    pop si  ;;Get back the address of the new node

    fn_exit 2

;Args - address of node to add to, address of node to add
ll_add_node:
    fn_enter

    fn_get_arg 1
    mov si, ax

    fn_get_arg 2
    mov di, ax

    mov ax, word [di + ll_node.next]
    mov word [si + ll_node.next], ax

    mov word [di + ll_node.next], si 
    mov word [si + ll_node.prev], di
    fn_exit 2

;Args - Start of LL to print
; Prints:
;   prev < curr, size > next
ll_print:
    fn_enter

    push .msg
    call sprint

    fn_get_arg 1
    mov si, ax
.loop:
    push word [si + ll_node.prev]
    call hprint

    push "<"
    call cprint

    push si
    call hprint

    push ","
    call cprint

    push word [si + ll_node.size]
    call hprint

    push ">"
    call cprint
    
    push word [si + ll_node.next]
    call hprint

    call newline

    cmp word [si + ll_node.next], 0
    je .done

    mov si, word [si + ll_node.next]
    jmp .loop

.done:
    fn_exit 1

.msg: db 'prev<curr,size>next', 10, 13, 0

;The BIG ONE!
;Args - size wanted
;   The plan: walk the LL untul we see a block larger than AX
; Ret - SI, address to new node
malloc:
    fn_enter
    fn_get_arg 1

    ;;Start at the end of the kernel
    mov si, _start_of_mem
.loop:
    ;;Is this block big enough to split?
    cmp ax, word [si + ll_node.size]
    jg .found

.cont:
    ;;Are we at a dead end? (aka: is .next set to null?)
    cmp word [si + ll_node.next], 0
    je .err

    ;;If not, then step
    mov si, word [si + ll_node.next]
    jmp .loop

.err:
    ;;There is no suitable block
    push .error_msg
    call sprint
    fn_exit 1

.found:
    ;;Check if it's used
    cmp word [si + ll_node.flags], REGION_USED
    je .cont ;;If used, keep searching

    ;;We have a suitable block
    push si ;;Pointer to region
    push ax ;;Size of requested block
    call split_region

    ;;Mark it as used
    mov word [si + ll_node.flags], REGION_USED
    fn_exit 1

.error_msg: db "NO FREE SPACE!", 10, 13, 0

free:
    fn_enter
    fn_exit 1
