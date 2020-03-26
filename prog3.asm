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
i 	db ?
j 	db ?

	.code
	mov ax, @data
	mov ds, ax
	mov es, ax
	cmp n, 0
	jle er
	cld
	lea si, matrix
	movzx cx, n
	mov i, 0
loop1:
	push si; stack: addr a[i][0]
	lodsb ; ax = a[i][0], si = addr a[i][1]
	mov bx, i
	inc bx
	mov i, bx
	push cx; stack: (n-i), addr a[i][0]
	mov j, 0
loop2:
	mov bx, j
	inc bx
	mov j, bx
	lodsb; ax = a[i][j], si = addr a[i][j+1]
	push ax; stack: a[i][j], n-i, addr a[i][0]
	mov ax, j
	lea si, matrix
	mov bx, n
	mul bx; ax = j * n
	mov bx, i
	add ax, bx; ax = j * n + i
	add si, ax; si = addr a[j][i]
	lodsb; ax = a[j][i]
	pop bx; bx = a[i][j]; stack: n-i, addr a[i][0]
	cmp ax, bx
	jne false
	push bx; stack: a[i][j], n-i, addr a[i][0]
	mov ax, n
	dec ax
	sub ax, j; ax = n -1-j
	lea si, matrix
	mov dx, n
	mul dx; ax = n * (n-1-j)
	add ax, dx
	dec ax
	sub ax, i
	add si, ax; si = addr a[n-1-j][n-1-i]
	lodsb
	pop bx
	cmp ax, bx
	jne false
	loop loop2
	pop cx
	pop si
	add si, n
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