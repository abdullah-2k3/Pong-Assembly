org 0x0100
	jmp start
	
	
oldisr: dd 0



printnum: push bp 
	 mov bp, sp 
	 push es 
	 push ax 
	 push bx 
	 push cx 
	 push dx 
	 push di 
	 push si
	 mov si, 0
	 mov ax, 0xb800 
	 mov es, ax ; point es to video base 
	 mov ax, [bp+4] ; load number in ax 
	 cmp ax, 0
	 je _pexit
	 
	 mov cx, 0 ; initialize count of digits 
nextdigit:
	 mov bx, 10
	 mov dx, 0 ; zero upper half of dividend 
	 div bx ; divide by 10 
	 add dl, 0x30 ; convert digit into ascii value 
	 push dx ; save ascii value on stack 
	 inc cx ; increment count of values 
	 cmp ax, 0 ; is the quotient zero 
	 jnz nextdigit ; if no divide it again 
	 mov di,  [bp+6]; 
nextpos:
	 pop dx ; remove a digit from the stack 
	 mov dh, 0x04 ; use normal attribute 
	 mov [es:di], dx ; print char on screen 
	 add di, 2 ; move to next screen location 
	 ;inc si
	 loop nextpos ; repeat for all digits on stack
_pexit:
	 pop si
	 pop di 
	 pop dx 
	 pop cx 
	 pop bx 
	 pop ax 
	 pop es 
	 pop bp 
	 ret 4


printscreen:
	pusha
	mov ax, 0xb800
	mov es, ax
	mov di, 0
	
	mov al, ' '
	mov ah, 0x00
	
	cld
	mov cx, 2000
	rep stosw
	
	mov di, 60
	mov al, '.'
	mov ah, 0x77
	mov cx, 20
	rep stosw
	
	
	mov di, 3900
	mov cx, 20
	rep stosw
	
	
	popa
	ret
	

print_ball:
	push bp
	mov bp, sp
	pusha
	
	mov ax, 0xb800
	mov es, ax
	
	mov ah, 0x07
	
	
	mov al, ' '
	mov di, [ball_loc]
	mov [es:di], ax
	
	
	mov al, '*'
	mov di, [bp+4]
	mov [es:di], ax
	mov [ball_loc], di
	
	
	
	popa
	pop bp
	ret 2



delay:
	push cx
	mov cx, 0xfff
.d: 
	nop
	nop
	loop .d
	mov cx, 0xffff
.dd:
	nop
	loop .dd
	
	pop cx
	ret
	


move_ball_down:
	push bp
	mov bp, sp
	pusha
	mov ah, 0x07
	
	mov di, [bp+4]
.l1:	
	push di
	call check_right_collision
	cmp word [change_down_direction], 1
	je sw
	
	push di
	call check_player_hit
	cmp word [check_hit], 1
	je near d
	
	call delay
	call delay
	mov al, ' '
	mov [es:di], ax
	add di, 162

	mov al, '*'
	mov [es:di], ax
	
	cmp word [left], 1
	jne .r
	push word 24
	call slide_left
.r:
	cmp word [right], 1
	jne .n
	push word 24
	call slide_right
.n:
	cmp di, 3840
	jl .l1
	add word [player1_score], 1
	mov word [p2_miss], 1
	jmp d
sw:
	push di
	call check_player_hit
	cmp word [check_hit], 1
	je d
	call delay
	call delay
	mov al, ' '
	mov [es:di], ax
	add di, 158
	mov al, '*'
	mov [es:di], ax
	
	cmp word [left], 1
	jne .r1
	push word 24
	call slide_left
.r1:
	cmp word [right], 1
	jne .n1
	push word 24
	call slide_right
.n1:
	cmp di, 3840
	jl sw
	add word [player1_score], 1
	mov word [p2_miss], 1
d:
	mov word [change_down_direction], 0
	mov [ball_loc], di
	popa
	pop bp
	ret 2




move_ball_up:
	push bp
	mov bp, sp
	pusha
	mov ah, 0x07
	
	mov di, [bp+4]
	
	
.l1:	
	push di
	call check_right_collision
	cmp word [change_up_direction], 1
	je switch
	
	push di
	call check_player_hit
	cmp word [check_hit], 1
	jne .no_hit
	jmp done
	
.no_hit:	
	call delay
	call delay
	mov al, ' '
	mov [es:di], ax
	sub di, 158

	mov al, '*'
	mov [es:di], ax
	
	cmp word [left], 1
	jne .r
	push word 0
	call slide_left
.r:
	cmp word [right], 1
	jne .n
	push word 0
	call slide_right
.n:
	cmp di, 160
	jg .l1
	add word [player2_score], 1
	mov word [p1_miss], 1
	jmp done
	
switch:
	mov word [change_up_direction], 0
	push di
	call check_player_hit
	cmp word [check_hit], 1
	je done

	call delay
	call delay
	mov al, ' '
	mov [es:di], ax
	sub di, 162
	mov al, '*'
	mov [es:di], ax
	
	cmp word [left], 1
	jne r1
	push word 0
	call slide_left
r1:
	cmp word [right], 1
	jne n1
	push word 0
	call slide_right
n1:
	push di
	call check_player_hit
	cmp word [check_hit], 1
	je done
	cmp di, 160
	jg switch
	add word [player2_score], 1
	mov word [p1_miss], 1
done:

	mov word [check_hit], 0
	mov [ball_loc], di
	popa
	pop bp
	ret 2


check_player_hit:
	push bp
	mov bp, sp
	pusha
	
	mov di, [bp+4]
	cmp word [player_turn], 1
	jne .p2
	sub di, 160
	mov ax, [es:di]
	cmp ah, 0x77
	jne .p1miss
	mov word [check_hit], 1
	jmp .done
.p1miss:
	mov word [check_hit], 0
	jmp .done
	
.p2:
	add di, 160
	mov ax, [es:di]
	cmp ah, 0x77
	jne .p2miss
	mov word [check_hit], 1
	jmp .done
.p2miss:
	mov word [check_hit], 0

.done	
	popa
	pop bp
	ret 2
	
	
check_right_collision:
	push bp
	mov bp, sp
	pusha
	
	mov bx, 3998
	
	mov cx, 23
.l1:
	cmp di, bx
	jne .next
	mov word [change_up_direction], 1
	mov word [change_down_direction], 1
	jmp .done
.next:
	sub bx, 160
	loop .l1

.done:	
	popa
	pop bp
	ret 2



slide_left:
	push bp
	mov bp, sp
	pusha
	mov ah, '.'
	mov di, [bp+4]
	mov cx, 80
	cmp di, 0
	je .p
	mov di, 3840
.p:
	mov ax, [es:di]
	cmp ah, 0x77
	jne .next
	sub di, 2
	mov ah, 0x77
	mov [es:di], ax
	add di, 40
	mov ah, 0x00
	mov [es:di], ax
	jmp .done
.next:
	add di, 2
	loop .p
	
.done:	
	mov word [left], 0
	popa
	pop bp
	ret 2


slide_right:
	push bp
	mov bp, sp
	pusha
	mov ah, '.'
	mov di, [bp+4]
	mov cx, 80
	cmp di, 0
	je .p
	mov di, 3840
.p:
	mov ax, [es:di]
	cmp ah, 0x77
	jne .next
	mov ah, 0x00
	mov [es:di], ax
	add di, 40
	mov ah, 0x77
	mov [es:di], ax
	jmp .done
.next:
	add di, 2
	loop .p
	
.done:	
	mov word [right], 0
	popa
	pop bp
	ret 2
	
	
	
kbisr:
	push ax
	push di
		
	in al, 0x60
	cmp al, 0x4b
	jne .nextcmp
	mov word [left], 1
	jmp .exit
.nextcmp:
	cmp al, 0x4d
	jne .ignore
	mov word [right], 1
	jmp .exit
.ignore:
	
	pop di
	pop ax
	jmp far [cs:oldisr]
	
.exit:
	mov al, 0x20
	out 0x20, al
	pop di
	pop ax
	iret
	
	
start:

	
	
	xor ax, ax
	mov es, ax
	mov ax, [es:9*4]
	mov [oldisr], ax
	mov ax, [es:9*4+2]
	mov [oldisr+2], ax
	
	cli
	mov word [es:9*4], kbisr
	mov word [es:9*4+2], cs
	sti
	
	call printscreen
	push word 3770
	call print_ball
	mov ah, 0
	int 0x16
	
	mov cx, 5
.l1:
	push 160
	push word [player1_score]
	call printnum
	
	push 3680
	push word [player2_score]
	call printnum
	
	push word [ball_loc]
	call move_ball_up

	mov word [player_turn], 2
	cmp word [p1_miss], 1
	jne .no_miss
	
	push word 260
	call print_ball
	mov word [p1_miss], 0
	mov ah, 0
	int 0x16
	
.no_miss:	
	push word [ball_loc]
	
	call move_ball_down
	
	mov word [player_turn], 1
	cmp word [p2_miss], 1
	jne .no_miss2
	
	push word 3770
	call print_ball
	mov word [p2_miss], 0
	mov ah, 0
	int 0x16
	
.no_miss2:	
	cmp word [player1_score], 6
	jl .next_cmp
	jmp quit
.next_cmp:
	cmp word [player2_score], 6
	jl .l1
	
	
quit:	
	mov ax, 0x4c00
	int 0x21


change_down_direction: dw 0
change_up_direction: dw 0
ball_loc: dw 0
left: dw 0
right: dw 0
player_turn: dw 1
check_hit: dw 0
player1_score: dw 1
player2_score: dw 1
p1_miss: dw 0
p2_miss: dw 0