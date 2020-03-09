; заменить в заданном слове комбинации 101 на комбинации 010

	.model small
	.stack 100h
	.486
	.data
	a dw 1010000010111111b
	.code
	mov ax, @data
	mov ds, ax
	mov dx, a
	mov bx, 0
lp: inc bx
	mov ax, dx
	xor ax, 5
	shl al, 5
	cmp al, 0
	je sb
cnt:rol dx, 1
	cmp bx, 16d
	jng lp
	jmp fn
sb: btc dx, 0
	btc dx, 1
	btc dx, 2
	jmp cnt
fn: mov ax, 4c00h
	int 21h
	end