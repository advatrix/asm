	.model medium
public	inputline,input,readfile,output,writefile,menu,algorithm
extrn	start:far; объявляем точку входа как внешнюю метку
extrn delim:byte
	.code; другой сегмент кодов. Он получит автоматически имя proc_text.
inputline	proc; принимает один параметр - буфер, куда будет введена строка. 
; Она удалит 13, 10 в конце строки и вместо этого запишет 0.
	locals @@
@@buffer	equ [bp+6]; ссылка на локальный параметр: bp + 2 - смещение возврата, bp + 4 - сегмент возврата, bp + 6 - первый параметр
	push bp
	mov bp,sp
	push ax
	push bx
	push cx
	push dx
	push di; для поиска 13 в строке
	mov ah,3fh; чтение из файла
	xor bx,bx; номер файла
	mov cx,80; макс размер строки
	mov dx,@@buffer; буфер, куда dos будет вводить информацию
	int 21h
	jc @@ex; в случае неудачи - устанавливается carry flag
	cmp ax,80; сколько символов введено + 13, 10. Если введено ровно 80, то пользователь явно ввёл что-то длинное, и оно обрубилось.
	jne @@m
	stc; формируем код ошибки - carry flag
	jmp short @@ex
@@m:	mov di,@@buffer; в ах - число введенных символов. Оно на два больше, чем длина имени.
	dec ax
	dec ax
	add di,ax; установили di на конец имени файла
	xor al,al; гарантированно сбрасывает carry flag
	stosb; помещаем 0 в конец строки, затирая 13.
@@ex:	pop di; обработкой ошибок будет заниматься внешняя функция. CF здесь не меняется.
	pop dx
	pop cx
	pop bx
	pop ax
	pop bp
	ret
	endp
input	proc; просто ввод многих строк до тех пор, пока не введем пустую строку.
	locals @@
@@buffer	equ [bp+6];единственный параметр
	push bp
	mov bp,sp
	push ax
	push bx
	push cx
	push dx
	push di
	xor bx,bx; чтение из 0 дескриптора
	mov cx,4095; предел на число символов
	mov dx,@@buffer
@@m1:	mov ah,3fh; чтение из файла
	int 21h
	jc @@ex; ошибка
	cmp ax,2; хранится число введённых символов, включая 2 символа в конце строки - 13 10. ax == 2 ==> была введена пустая строка.
	je @@m2
	sub cx,ax; cx никогда не будет отрицательным.
	jcxz @@m2; конец ввода - переполнение буфера
	add dx,ax; просим уже меньше символов. И вводить будем не в начало буфера, а с того места, где закончился ввод.
	jmp @@m1; продолжаем чтение
@@m2:	mov di,@@buffer; начало буфера
	add di,4095; прибавили максимальное значение буфера
	sub di,cx; всегда можно понять, сколько символов ввели. В итоге di укажет на место, на котором закончился ввод.
	xor al,al
	stosb; закрываем введённую информацию нулём.
@@ex:	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	pop bp
	ret
	endp
output	proc; вывод любой информации. Надо только заканчивать каждую строку 13 10 и конец ввода нулём.
	locals @@
@@buffer	equ [bp+6]
	push bp
	mov bp,sp
	push ax
	push bx
	push cx
	push dx
	push di
	mov di,@@buffer
	xor al,al
	mov cx,0ffffh
	repne scasb
	neg cx
	dec cx
	dec cx
	jcxz @@ex; если нул байт хранится сразу - буфер пустой, выводить нечего
	cmp cx,4095; не оказался ли буфер случайно больше - например, не закрыт нулём, защита от дурака
	jbe @@m;
	mov cx,4095; принудительное ограничение буфера
@@m:	mov ah,40h; запись в файл
	xor bx,bx
	inc bx; 1 - вывод на экран
	mov dx,@@buffer
	int 21h
@@ex:	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	pop bp
	ret
	endp
readfile	proc
	locals @@
@@buffer	equ [bp+6]; процедура принимает два параметра
@@filnam	equ [bp+8]
	push bp
	mov bp,sp
	push ax
	push bx
	push cx
	push dx
	push di
	mov ax,3d00h; открыть файл на чтение
	mov dx,@@filnam
	int 21h
	jc @@ex; неудача - файл не найден.
	mov bx,ax; в ах будет дескриптор. Его потом надо будет заносить в bx.
	mov cx,4095; формируем информацию для чтения - лимит
	mov dx,@@buffer; и буфер - куда читать
@@m1:	mov ah,3fh; чтение из файла
	int 21h
	jc @@er; неудача - но тут ещё надо файл закрыть.
	or ax,ax; файл пустой или достигли конца файла
	je @@m2
	sub cx,ax; могли прочитать не всё
	jcxz @@m2; всё прочитали
	add dx,ax
	jmp @@m1; повторяем чтение
@@m2:	mov di,@@buffer; в конец буфера надо записать нулевой байт.
	add di,4095
	sub di,cx; сколько мы прочитали. di будет указывать на конец прочитанной информации.
	xor al,al
	stosb; закрываем нулем.
	mov ah,3eh; закрываем файл
	int 21h
@@ex:	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	pop bp
	ret
@@er:	mov ah,3eh
	int 21h
	stc; сообщаем внешней функции об ошибке
	jmp @@ex
	endp
writefile proc
	locals @@
@@filnam	equ [bp+8]; куда писать
@@buffer	equ [bp+6]; что писать
	push bp
	mov bp,sp
	push ax
	push bx
	push cx
	push dx
	push di
	mov ah,3ch; создать файл или сделать его пустым.
	xor cx,cx; никаких атрибутов
	mov dx,@@filnam
	int 21h
	jc @@ex; ошибка
	mov bx,ax; файловый дескриптор переносим в bx
	mov di,@@buffer; нужно вычислить длину информации, заносимой в файл.
	xor al,al; ищем нулевой байт
	mov cx,0ffffh; 0 сначала, чтобы не было ошибки - в начале дб допустимый символ 0-9
	repne scasb
	neg cx
	dec cx
	dec cx
	jcxz @@ex1; ничего не надо писать
	cmp cx,4095
	jbe @@m
	mov cx,4095; слишком много писать
@@m:	mov ah,40h
	mov dx,@@buffer
	int 21h
	jc @@er
@@ex1:	mov ah,3eh
	int 21h
@@ex:	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	pop bp
	ret
@@er:	mov ah,3eh
	int 21h
	stc
	jmp @@ex
	endp
menu	proc
	locals @@
@@ax		equ [bp-82]; это локальные переменные bp-. Создаем кадр стека
@@buffer	equ [bp-80]; буфер ответа от пользователя
@@items	equ	[bp+6]; единственный параметр
	push bp
	mov bp,sp
	sub sp,80; в стеке останется кадр - свободное пространство 80 символов для локальных параметров. Надо помнить, что
	; при адресации к стеку сегментный регистр не ds, а ss.
	push ax
@@m:	push @@items
	call output; выводим альтернативы меню
	pop ax
	jc @@ex; ошибка вывода. В противном случае делаем манипуляции со стеком
	push ds ; сохраняем для дальнейшего восстановления ds, es, ss. Надо сделать es и ds равными ss.
	push es
	push ss
	push ss; два раза, 
	pop ds; ds = ss
	pop es; es = ss
	mov ax,bp
	sub ax,80
	push ax
	call inputline; использует регистр стека как буфер
	pop ax
	pop es; восстанавливаем как было
	pop ds
	jc @@ex
	mov al,@@buffer; надо преобразовать код введенного символа в номер пункта меню 
	cbw; анализируем первый введённый символ
	sub ax,'0'; вычитаем код нуля
	cmp ax,0; если число меньше нуля -- ввели не цифру
	jl @@m
	cmp ax,@@ax; код символа слишком большой
	jg @@m; повторяем попытку ввода 
	clc
@@ex:	mov sp,bp; восстанавливаем кадр стека
	pop bp
	ret
	endp

algorithm	proc
	locals @@
@@ibuf	equ [bp+6]; буфер с исходными строками. equ - аналогично сишному define
@@obuf	equ [bp+8]; буфер, куда надо записать ответ
	push bp
	mov bp,sp
	push ax
	push bx
	push cx
	push si
	push di

	mov cx,0ffffh
	mov di,@@ibuf
	xor al,al
	repne scasb; считаем длину буфера с исходными строками
	neg cx
	dec cx
	dec cx; cx = len(ibuf)
	jcxz @@exit
	cmp cx,4095
	jbe @@m1; cx > 4095 ==> error
	stc
	jmp short @@exit; ошибка
	mov di, @@ibuf
	mov si, @@obuf
	mov bx, si
	add bx, cx; get in bx pointer to the end
	
@@m1:
	call space; si = first non-space character
	cmp byte ptr [si], 13
	je @@nextline
	cmp si, bx
	je @@finish
	call _word
	push ax
	call reverse
	inc sp
	inc sp
	cmp byte ptr[si], 13
	je @@nextline
	cmp si, bx
	je @@finish
	mov al, ' '
	stosb
	jmp @@m1
	
@@nextline:
	cmp byte ptr [si+1], 10; line should end with 13 10
	jne @@error; 10 doesn't go after 13
	lodsb; read 13
	stosb; write 13
	lodsb; read 10
	stosb; write 13
	jmp @@m1
	
@@error:	shl bx,1; надо восстановить стек, раз произошла ошибка. В bx хранится число строк, которые мы уже записали.
	add sp,bx; восстанавливаем состояние стека до начала работы со строками
	stc; устанавливаем флаг ошибки
	jmp short @@exit
@@finish:	
	xor al, al
	stosb
@@exit:
	pop di
	pop si
	pop cx
	pop bx
	pop ax
	pop bp
	ret
	endp
	
	
	

reverse proc 
	locals @@
	
	push ax
	push bx
	push cx
	push bp
	
	mov cx, [bp+10]
	sub cx, si
	mov bx, cx
	xor ax, ax
	
@@cycm1:
	lodsb
	push ax
	loop @@cycm1
	mov cx, bx
	
@@cycm2:
	pop ax
	stosb
	loop @@cycm2
	
	pop bp
	pop cx
	pop bx
	pop ax
	ret
	endp



_word proc
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
	
@@m:
	pop cx
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
	
	xor al, al
	mov cx, 65535
	repne scasb
	neg cx
	dec cx
	push cx
	
@@m1:
	pop cx
	pop di
	push di
	push cx
	lodsb
	repne scasb
	jcxz @@m2
	jmp @@m1
	
@@m2:
	dec si
	add sp, 4
	pop di
	pop cx
	pop ax
	ret
	endp
	
	end start

