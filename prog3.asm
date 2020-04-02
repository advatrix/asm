; is a matrix symmetric?

	.model small
	.stack 100h
	.486
	
	.data
n	dw 4
matrix db 1, 3, 7, 5
	db 3, 2, 6, 7
	db 7, 6, 2, 3
	db 5, 7, 3, 1
i 	dw ?
j 	dw ?

	.code
	mov ax, @data
	mov ds, ax
	mov es, ax
	cmp n, 0
	jle er
	cld
	lea si, matrix
	mov cx, n
	mov i, 0
loop1:
	push si; stack: addr a[i][0]
	push cx; stack: (n-i), addr a[i][0]
	mov j, 0
loop2:																					
	lea si, matrix
	mov ax, n
	mov bx, i
	mul bx
	add ax, j
	add si, ax
	xor ax, ax
	lodsb; ax = a[i][j], si = addr a[i][j+1]
	push ax; stack: a[i][j], n-i, addr a[i][0]
	mov ax, j
	lea si, matrix
	mov bx, n
	mul bx; ax = j * n
	add ax, i; ax = j * n + i
	add si, ax; si = addr a[j][i]
	xor ax, ax
	lodsb; ax = a[j][i]
	pop bx; bx = a[i][j]; stack: n-i, addr a[i][0]
	cmp ax, bx
	jne false
	
	
	push bx; stack: a[i][j], n-i, addr a[i][0]
	mov ax, n
	dec ax; ax = n - 1
	sub ax, j; ax = n -1-j
	lea si, matrix; si = addr a[0][0]
	mov bx, n
	mul bx; ax = n * (n-1-j)
	add ax, bx; ax = n * (n - 1 - j) + n 
	;dec ax
	sub ax, i
	dec ax
	add si, ax; si = addr a[n-1-j][n-1-i]
	xor ax, ax
	lodsb
	pop bx; 
	cmp ax, bx; here ax != bx!!!!
	jne false
	mov bx, j
	inc bx
	mov j, bx
	xor ax, ax
	loop loop2
	pop cx
	pop si
	add si, n
	mov bx, i
	inc bx
	mov i, bx
	loop loop1
	xor ax, ax
	inc ax
	jmp ex
false: xor ax, ax
	jmp ex
ex:	mov ax, 4c00h
	int 21h
er:	mov ax, 4c01h
	int 21h
	end