; в каждом слове строки поменять порядок букв на обратный
; слова в строке могут быть разделены пробелом, запятой или точкой с запятой.

	.model small
	.stack 100h
	.486
	.data
string db '  ; a ,,	quick   brown,fox  jumps  ; over the; lazy dog', 0
delim ds ' ,;', 0
newstring db 100 dup(?) ; for result
	
	.code
	mov ax, @data
	mov ds, ax
	mov es, ax
	cld
	lea si, string ; source
	lea di, newstring ; destination
	
m1:	call space
	cmp byte ptr [si], 0
	je fin
	call _word
	push ax
	call reverse
	inc sp
	inc sp
	cmp byte ptr [si], 0
	je fin
	mov al, ' '
	stosb
	jmp m1
	
fin:
	xor al, al
	stosb
	mov ax, 4c00h
	int 21h


; code: 
; 
reverse proc ; (si: ptr to the start, stack: ptr to the end, di: ptr to the destination)
	locals @@
	push bp
	mov bp, sp
	
	push ax
	push bx
	push cx
	
	mov cx, [bp+4]
	sub cx, si
	mov bx, cx
	xor ax, ax
	
@@cycm1:	
	lodsb
	push ax
	loop cycm1
	
	mov cx, bx
	
@@cycm2:
	pop ax
	stosb
	loop cycm2

	pop cx
	pop bx
	pop ax
	pop bp
	ret
	endp


_word proc ; returns in ax ptr to the first delim after word
	locals @@
	push si
	push cx
	push di
	
	lea di, delim
	push di
	
	xor al, al
	mov cx, 65535
	repne scasb
	neg cx
	push cx
	
@@m:	pop cx
	pop di
	push di
	push cx
	lodsb
	repne scasb
	jcxz @@m
	
	dec si
	mov ax, si
	add sp, 4
	pop di
	pop cx
	pop si
	ret
	endp


space proc
	locals @@
	push ax
	push cx
	push di
	
	lea di, delim
	push di
	
	xor al, al
	mov cx, 65535
	repne scasb
	neg cx
	dec cx
	push cx
	
@@m1:	pop cx
	pop di
	push di
	push cx
	lodsb
	repne scasb
	jcxz @@m2
	jmp @@m1
	
@@m2:	dec si
	add sp, 4 
	pop di
	pop cx
	pop ax
	ret
	endp
	
	end
	

