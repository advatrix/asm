Программа должна обеспечить шифрование фалйа методом гаммирования.
Гамма 64-битная задется в командной строке в виде набора 16 16-ричных цифр. 
Имя исходного и результирующего файлов задаются  командной строке. 
Программа должна корректно обрабатывать неверную командную строку, а также результаты файловых операций.

	.model compact
	.stack 100h
	.data
fdr	dw ?; хранение файлового дескриптора на чтение
fdw	dw ?; на запись
par	dw 3 dup (?); указатели на начала параметров командной строки
parl	db 3 dup (?); длины параметров командной строки
msg1	db 'Usage: crypto key filein fileout',13,10
	db '	crypto - 64-bit hex value',13,10
	db 'Crypto Version 1.0 Copyright (c) 2020 Dozen',13,10,0
msg2	db 'Incorrect key: Key must consist of 16 16-digit number',13,10,0
msg3	db ': Cannot open',13,10,0
msg4	db ': Cannot create',13,10,0
msg5	db 'Input/output error',13,10,0
key	db 16 dup (?)
keybin	db 8 dup (?)
filein	db 80 dup (?); имена файлов
fileout	db 80 dup (?)
	.fardata; второй сегмент данных.
	db 65520 dup (?); равен 64К-1. Кратен 16.
	.code
	.486; если мы укажем его раньше, сегмент .fardata будет считаться за 32 битный, а так 16
	mov ax,@data
	mov ds,ax; изначально ds и es указывают на префикс программного сегмента psp, в котором хранится в т.ч. и командная строка.
	; из es как раз можно будет потом взять префикс командного сегмента.
	cld
	movzx cx,es:[80h]; длина хвоста команды с параметрами
	jcxz m3; запустили программу без параметров
	xor bx,bx; счётчик параметров
	mov di,81h; адрес начала параметров командной строки
	mov al,' '; в начале параметров - пробелы
m1:	repe scasb; ищем первый параметр, пропуская пробелы перед первым словом
	dec di; di будет указывать на второй символ в слове, поэтому его надо уменьшить
	inc cx; синхронизируем с di число оставшихся символов в командной строке
	shl bx,1; 
	mov par[bx],di; занесли адрес начала первого параметра
	shr bx,1; 
	push di; ищем конец параметра
	repne scasb
	dec di
	pop dx; извлекаем адрес начала слова
	sub dx,di
	neg dx; нашли длину параметра командной строки
	mov parl[bx],dl; занесли длину
	inc bx; обработали этот параметр
	jcxz m2; параметры закончились
	inc cx; синхронизируем с di
	jmp m1
m2:	cmp bx,3
m3:	jne er
	inc parl[bx-1]; надо увеличить длину последнего параметра, потому что мы вышли из верхнего цикла по обнулению cx, а не по нахождению конца
	cmp parl,16
	jne erkey; ключ не из 16 символов
	push ds; надо преобразовать ключ в двоичный формат
	push es; меняем местами регистры, чтобы копировать данные
	pop ds
	pop es
	mov cx,16; копируем ключик
	mov si,es:par; адрес начала ключа. Используем es, потому что es сейчас играет роль сегмента данных
	lea di,es:key; 
	rep movsb; копируем 16 16-ричных цифр из командной строки в key
	movzx cx,es:parl+1; аналогично со вторым параметром - имя исходного файла
	mov si,es:par+2
	lea di,es:filein
	rep movsb
	xor al,al; закрываем имя файла нулевым байтом
	stosb
	movzx cx,es:parl+2
	mov si,es:par+4
	lea di,es:fileout
	rep movsb
	stosb; закрываем нулевым байтом опять
	mov cx,8; обрабатываем ключ - нам нужно 8 байт из 16 16-ричных цифр
	push es; больше префикс программного сегмента не нужен
	pop ds; настраиваем ds на сегмент данных
	lea si,key; копируем ключ, преобразовываем и пишем в keybin. Будем считывать по 2 цифры и преобразовывать их в байт.
	lea di,keybin
m4:	lodsb
	call hex; преобразует 16-ричную цифру в байт
	cmp al,0ffh; ошибка при преобразовании
	je erkey
	mov ah,al; временно запоминаем первую цифру
	shl ah,4; умножаем ah на 4, сдвинув первую цифру
	lodsb
	cmp al,0ffh
	je erkey
	or al,ah; сформироали в al байт
	stosb
	loop m4
	mov ax,3d00h; открываем исходный файл на чтение
	xor cx,cx
	lea dx,filein
	int 21h
	jc erfilein
	mov fdr,ax
	mov ah,3ch
	xor cx,cx
	lea dx,fileout
	int 21h
	jc erfileout; не удалось создать файл
	mov fdw,ax; записываем файловый дескриптор
	mov ax,seg far_data; записываем сегментный адрес far_data
	mov ds,ax; ds настроен на другой сегмент данных. На прежний сегмент остался настроен es.
m5:	mov bx,es:fdr; дескриптор на чтение
	mov cx,65520; буфер
	xor dx,dx; пишем с самого начала сегмента
m6:	mov ah,3fh; чтение из файла
	int 21h
	jc erio
	or ax,ax; после чтения в ax вернулось реально прочитанное число байт. Если ничего не считалось, прыгаем на m7.
	je short m7
	add dx,ax; настраиваем на повторное чтение
	sub cx,ax; нужно прочитать остаток
	jcxz m7; действительно прочитали всё
	jmp m6; если нет, продолжаем чтение
m7:	or dx,dx; конец обработки
	je short m10; конец обработки файла, выход из программы
	sub cx,65520; надо шифровать и писать в новый файл. Узнаём размер считанных данных
	neg cx
	push cx
	shr cx,3; делим на 8 - число итераций цикла в 8 раз меньше, чем размер
	inc cx; округление в большую сторону
	mov eax,dword ptr es:keybin; младшая часть гаммы шифра
	mov edx,dword ptr es:keybin+4; старшая часть гаммы шифра
	xor bx,bx
m8:	xor [bx],eax; шифрование
	xor [bx+4],edx
	add bx,8
	loop m8
	pop cx; вспоминаем, сколько реально было байтов. Теперь зашифрованные байты надо записать в результирующий файл
	mov bx,es:fdw
	xor dx,dx
m9:	mov ah,40h; пишем в файл
	int 21h
	jc short erio; не удалось записать
	or ax,ax
	je short erio; ничего не записалось -- ошибка ввода-вывода
	add dx,ax; сколько записалось
	sub cx,ax; вычитаем сколько осталось
	jcxz m5; больше ничего не осталось
	jmp m9; дозаписываем
m10:	mov ah,3eh
	mov bx,es:fdr; закрываем файл на чтение
	int 21h
	mov ah,3eh
	mov bx,es:fdw
	int 21h
	xor al,al; корректное завершение программы
ex:	mov ah,4ch
	int 21h
er:	push offset msg1
	call output
	mov al,1; код ошибки
	jmp ex
erkey:	push offset msg2
	call output; выводим сообщение об ошибке
	mov al,2; ошибка ключа - другой код
	jmp ex
erfilein: push offset filein
	call output
	push offset msg3
	call output
	mov al,3
	jmp ex
erfileout: mov ah,3eh; закрываем файл на чтение
	mov bx,fdr
	int 21h 
	push offset fileout
	call output
	push offset msg4
	call output
	mov al,4
	jmp ex
erio:	push es; ошибка ввода-вывода. К этому моменту оба файла открыты, их надо закрыть, а к тому же ещё и заменён ds.
	pop ds; восстанавливаем ds
	mov ah,3eh
	mov bx,fdr
	int 21h
	mov ah,3eh
	mov bx,fdw
	int 21h
	push offset msg5
	call output
	mov al,5; завершаем программу с кодом 5
	jmp ex
hex	proc
	locals @@
	cmp al,'0'
	jb short @@er
	cmp al,'9'
	ja @@m1
	sub al,'0'
	jmp short @@ex
@@m1:	cmp al,'A'
	jb short @@er
	cmp al,'F'
	ja @@m2
	sub al,'A'-10
	jmp short @@ex
@@m2:	cmp al,'a'
	jb short @@er
	cmp al,'f'
	ja @@er
	sub al,'a'-10
	jmp short @@ex 
@@er:	mov al,0ffh
@@ex:	ret
	endp
output	proc
	locals @@
@@message	equ [bp+4]
	push bp
	mov bp,sp
	push ax
	push bx
	push cx
	push dx
	push di
	push ds
	push es
	push ds
	pop es
	mov di,@@message
	mov cx,4096
	xor al,al
	repne scasb
	sub cx,4095
	neg cx
	mov ah,40h
	xor bx,bx
	inc bx
	mov dx,@@message
	int 21h
	pop es
	pop ds
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	pop bp
	ret 2; высвобождаем параметр сами
	endp
	end
