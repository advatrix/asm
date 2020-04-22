; в каждом слове строки поменять порядок букв на обратный
; слова в строке могут быть разделены пробелом, запятой или точкой с запятой.

	.model small
	.stack 100h
	.486
	.data
string db '  ; a ,,	quick   brown,fox  jumps  ; over the; lazy dog', 0
delim db ' ,;', 0
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
	call _word; ax = addr of first space after the word
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
reverse proc c uses ax bx cx; (si: ptr to the start, stack: ptr to the end, di: ptr to the destination)
	locals @@
	
	push bp
	mov bp, sp
	
	mov cx, [bp+10]
	sub cx, si; cx = len(word)
	mov bx, cx
	xor ax, ax; ax = 0
	
@@cycm1:	
	lodsb; al = word[cx], si += 1
	push ax; stack: word[si], word[si-1], ... , bp
	loop @@cycm1
	mov cx, bx; cx = len(word)
	
@@cycm2:
	pop ax; ax = word[-cx]
	stosb
	loop @@cycm2
	pop bp
	ret
	endp


_word proc c uses si cx di ; returns in ax ptr to the first delim after word
	locals @@
	
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
	ret
	endp


space proc c uses ax cx di
	locals @@
	
	lea di, delim
	push di; stack: addr delim
	
	xor al, al
	mov cx, 65535
	repne scasb
	neg cx
	dec cx; cx = len(delim)
	push cx; stack: len(delim), addr delim
	
@@m1:	pop cx; cx = len(delim)
	pop di; di = addr(delim), stack is empty
	push di; stack: addr(delim)
	push cx; stack: len(delim), addr(delim)
	lodsb; al = string[si], si += 1
	repne scasb
	jcxz @@m2
	jmp @@m1
	
@@m2:	dec si
	add sp, 4 
	ret
	endp
	
	end
	

