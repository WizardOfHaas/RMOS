    db 'mem.asm'

%define REGION_USED "U"

struc ll_node
    .prev_seg resw 1
    .prev: resw 1
    .next_seg resw 1
    .next: resw 1
    .size: resw 2
    .flags: resb 1 
endstruc

%macro make_ll_node 8
    mov word %1:[%2 + ll_node.prev_seg], %3
    mov word %1:[%2 + ll_node.prev], %4
    mov word %1:[%2 + ll_node.next_seg], %5
    mov word %1:[%2 + ll_node.next], %6
    mov word %1:[%2 + ll_node.size], %7
    mov byte %1:[%2 + ll_node.flags], %8
%endmacro

%define get_node_size(s, o) word s:[o + ll_node.size]
%define get_node_next(s, o) word s:[o + ll_node.next]
%define get_node_prev(s, o) word s:[o + ll_node.prev]
%define get_node_next_seg(s, o) word s:[o + ll_node.next_seg]
%define get_node_prev_seg(s, o) word s:[o + ll_node.prev_seg]

%macro ll_next 0-3 si, es, si
    mov %2, get_node_next_seg(%2, %1)
    mov %3, get_node_next(%2, %1)
%endmacro

%macro set_node_prev 4
    mov word %1:[%2 + ll_node.prev_seg], %3
    mov word %1:[%2 + ll_node.prev], %4
%endmacro

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

    ;;I need to make a pile of 64k segments and give each an LL header
    ;;  Once I have this set up I can change the malloc to just dole out free segs
    ;;  ...and NOT bother splitting them
    ;;  I'll keep in the code to split for later when I need heap allocation

    push 0x10
    pop es
    make_ll_node es, 0, 0, 0, 0, 0, 0xFFFF, 0

    ;;---THIS IS THE OLDER WAY---
    ;;make_ll_node cs, _start_of_mem, 0, 0, 0, 0, 0xFFFF - _start_of_mem - ll_node, 0

    fn_exit

;Splits off a chunk of a node
;Args - node to split, size of new node
;Ret - SI, address to new node
split_region:
    fn_enter

    fn_get_arg 3, es    ;;Node to split
    fn_get_arg 2, si

    fn_get_arg 1, ax    ;;Size of new node

    ;TODO: Check the node has enouhg space... this should be a PANIC

    ;Calculate start of new chunk (end of region - header - new_size)
    mov di, si                       ;;DI will be the Destination of the new block
    add di, get_node_size(es, si)    ;;Skip to end of region
    sub di, ll_node_size             ;;Subtract header size
    sub di, ax                       ;;Subtract new region size

    push di                          ;;Save for return

    ;;[DI now points to new header location]

    ;;Get the pointer to NEXT from the split node
    mov bx, get_node_next(es, si)
    mov fs, get_node_next_seg(es, si)

    ;Make new LL header
    make_ll_node es, di, es, si, es, bx, ax, REGION_USED

    ;;Now we adjust our neighbors
    cmp bx, 0   ;;Did the pslit node have a NEXT?
    je .no_next

    ;;If the split node had a NEXT then I need to get the NEXT's PREV
    set_node_prev fs, bx, es, di

.no_next:
    sub word es:[si + ll_node.size], ax    ;Update existing LL header size

    mov word es:[si + ll_node.next], di    ;Set split block to point to new block
    mov word es:[si + ll_node.next_seg], es

    pop si  ;;Get back the address of the new node

    fn_exit 3

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

    fn_get_arg 1, si
    fn_get_arg 2, es
.loop:
    push word es:[si + ll_node.prev_seg]
    call hprint

    push ":"
    call cprint

    push word es:[si + ll_node.prev]
    call hprint

    push "<"
    call cprint

    push es
    call hprint

    push ":"
    call cprint

    push si
    call hprint

    push ","
    call cprint

    push word es:[si + ll_node.size]
    call hprint

    push ">"
    call cprint
    
    push word es:[si + ll_node.next_seg]
    call hprint

    push ":"
    call cprint

    push word es:[si + ll_node.next]
    call hprint

    call newline

    cmp word es:[si + ll_node.next], 0
    je .done

    ;;mov si, word es:[si + ll_node.next]
    ll_next
    jmp .loop

.done:
    fn_exit 2

.msg: db '     prev<     curr,size>     next', 10, 13, 0

;The BIG ONE!
;Args - size wanted
;   The plan: walk the LL untul we see a block larger than AX
; Ret - SI, address to new node
malloc:
    fn_enter
    fn_get_arg 1

    ;;Start at the end of the kernel
    push cs
    pop es
    mov si, _start_of_mem
.loop:
    ;;Is this block big enough to split?
    cmp ax, word es:[si + ll_node.size]
    jg .found

.cont:
    ;;Are we at a dead end? (aka: is .next set to null?)
    cmp word es:[si + ll_node.next], 0
    je .err

    ;;If not, then step
    mov si, word es:[si + ll_node.next]
    jmp .loop

.err:
    ;;There is no suitable block
    push .error_msg
    call sprint
    fn_exit 1

.found:
    ;;Check if it's used
    cmp word es:[si + ll_node.flags], REGION_USED
    je .cont ;;If used, keep searching

    ;;We have a suitable block
    push es
    push si ;;Pointer to region
    push ax ;;Size of requested block
    call split_region

    ;;Mark it as used
    mov word es:[si + ll_node.flags], REGION_USED
    fn_exit 1

.error_msg: db "NO FREE SPACE!", 10, 13, 0

free:
    fn_enter
    fn_exit 1