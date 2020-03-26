; is a matrix symmetric?

	.model small
	.stack 100h
	.486
	.data
n	db 4
matrix db 1, 2, 3, 4
	db 2, 2, 5, 1
	db 3, 5, 3, 2
	db 4, 1, 2, 4
string db ?
	
	.code
	mov ax, @data
	mov ds, ax
	mov es, ax
	cmp n, 0 ; матрица 0 * 0
	jle er
	cld ; работаем в сторону увеличения адресов
	lea si, matrix
	movzx ax, n
	mov cx, ax
loop1:	lodsb; ax = a[i] (for i = 1...n), si = i+1
	push cx ; saved external cycle param
; we have to compute a[i][j]
	push si; stack: si, cx
	movzx cx, n
	push ax ; saved a[i]
loop2:	movzx ax, n
	sub ax, cx ; ax = j
	mov dx, ax; dx = j
	pop bx ; bx = a[i], stack : cx
	push bx ; return a[i] to stack
	add ax, bx ; ax = a[i][j]
	push ax; saved a[i][j], stack: a[i][j] a[i] cx
; we have to compute a[j][i]
	push si; saved si = i + 1, stack: i + 1,  a[i][j], a[i], cx
	lea si, matrix; si = a
	movzx bx, n
	mov ax, bx
	sub ax, cx; ax = j
	mul ax, bx; ax = j * n
	add si, ax; si = a[j * n] = a[j]
	pop ax; ax = i + 1, stack: a[i][j], a[i], cx
	dec ax; ax = i
	add si, ax; si = a[j][i]
	lodsb; ax = a[j][i], si = i + 1
	pop bx; bx = a[i][j], stack: a[i], cx
	cmp ax, bx
	jne false
; теперь надо проверить на симметричность относительно побочной (a[i][j] = a[n-1-j][n-1-i])
	push bx; stack: a[i][j], a[i], cx
	movzx bx, n ; bx = n
	dec bx; bx = n -1
	push bx; stack: n - 1, a[i][j], a[i], cx
	sub bx, dx; bx = n - 1 - j
	movzx ax, n
	mul ax, bx; ax = a[n-1-j]
	pop bx; stack: a[i][j], a[i], n - i
	sub bx, si; bx = n - 2 - i
	inc bx
	add ax, bx; ax = addr a[n-1-j][n-1-i]
	lea si, matrix
	add si, ax
	lodsb; ax = a[n-1-j][n-1-i], stack: a[i][j], a[i], ext si, ext cx
	push bx; stack: a[i], ext si, ext cx
	cmp ax, bx
	jne false
	loop loop2
	pop si
	pop cx
	loop loop1
	xor ax, ax
	inc ax
	jmp ex
false: xor ax, ax
	jmp ex
ex:	int 21h
er:	mov ax, 4c01h
	jmp ex
	end