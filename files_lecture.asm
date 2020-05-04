Программа должна записать все строки в текстовом файле в обратном порядке. 
Программа должна обеспечивать с помощью меню выбор источника файла: клавиатура или имя файла, результата: экран или имя файла.
Программа должна корректно обрабатывать результаты файловых операций. Запуск:
>tasm main ; создать main.obj
>tasm data ; data.obj
>tasm proc ; proc.obj
>tlink main data proc ; при корректном программировании порядок не имеет значения - если указана точка входа
>main ; или main.exe

Файл main.asm ; only program, data in data file
	.model medium ; split file to two files ==> процедуры дальнего вызова. Два сегмента кода ткак как два файла.
	.stack 100h
public	start; транслируем метку старт, делаем её доступной
extrn	items:byte; данных нет, они внешние, помечаем их тип
extrn	fn:byte
extrn	ibuf:byte; input buf
extrn	obuf:byte; output buf - туда записывается результат алгоритма
extrn	msg:byte
extrn	frm:byte
extrn	qws:byte
extrn	inp:byte
extrn	bye:byte; либо строки, либо место для данных
extrn	input:far; вызовы процедур - дальние вызовы. Метки занимают 4 байта - сегмент кода:смещение
extrn	inputline:far
extrn	readfile:far
extrn	output:far
extrn	writefile:far
extrn	menu:far
extrn	algorithm:far
	.code; имя сразу после сегмента, если сегментов кода несколько
start:	mov ax,@data; точка входа в программу
	mov ds,ax
	mov es,ax
	cld
m1:	mov ax,5; вывести на экран меню, чтобы бользовательв выбрал альтернативу - 6 альтернатив 
	push offset items
	call menu; принимает два параметра - через ах число пунктов меню (от 0 до ах), второй через стек - сообщения для вывода
	pop bx; освобождаем стек. Но процедура возвращает carry flag в случае ошибки, поэтому делаем pop bx, чтобы не испортить флаги
	jnc m2; нет ошибки - прыгаем на m2 
	push offset msg
	call output; выводит просто сообщение об ошибке
	pop bx
	jmp m10; - переход на завершение программы
m2:	cmp ax,1; после выхода из menu в ax находится номер выбранной альтернативы
	jne m3
	push offset inp; ввод информации с клавиатуры. Последнюю строку надо ввести пустую - это будет означать конец ввода.
	call output; поясняющее сообщение
	pop bx
	push offset ibuf; обеспечиваем ввод
	call input; принимает только один параметр - смещение буфера, в который она запишет весь текст. 
	;Она автоматически закроет его нулем.
	pop bx; clear stack
	jc m4; ошибка ввода - переходим на m4.
	jmp m1; снова просим ввести новую альтернативу. Например, обработать
m3:	cmp ax,2; выбрана альтернатива 2 - ввод из файла.
	jne m5
	push offset qws
	call output
	pop bx
	push offset fn
	call inputline; вводит только одну строку 
	pop bx
	jc m4; ошибка ввода
	push offset fn; имя файла
	push offset ibuf; буфер
	call readfile; процедура принимает два параметра: имя файла и адрес буфера
	pop bx
	pop bx
	jc m4
	jmp m1; просим ввести новую альтернативу
m4:	jmp m11; это впомогательная метка, чтобы перепрыгнуть далеко
m5:	cmp ax,3; выбран вывод информации на экран
	jne m6
	push offset obuf
	call output
	pop bx
	jc m4
	jmp m1
m6:	cmp ax,4; выбран выод информации в файл
	jne m7
	push offset qws
	call output
	pop bx
	push offset fn
	call inputline
	pop bx
	jc m11; сразу прыгаем на m11, потому что уже подошли ближе
	push offset fn
	push offset obuf
	call writefile
	pop bx
	pop bx
	jc m11
	jmp m1
m7:	cmp ax,5; запуск алгоритма
	jne m9
	push offset obuf
	push offset ibuf
	call algorithm
	pop bx
	pop bx
	jc m8; обработки не произошло. Алгоритм проверяет корректность информации.
	jmp m1
m8:	push offset frm
	call output
	pop bx
	jmp m1
m9:	push offset bye; пользователь выбрал 0 альтернативу - завершение работы
	call output
	add sp,2
m10:	mov ax,4c00h
	int 21h
m11:	push offset msg; вывести сообщение об ошибке
	call output
	pop bx
	jmp m1
	end start

Файл data.asm; тут только данные
	.model medium
public	items,fn,ibuf,obuf,msg,frm,qws,inp,bye; делаем все метки доступными для внешних файлов
	.data
items	db '1. Input from keyboard',13,10
	db '2. Read from file',13,10
	db '3. Output to screen',13,10
	db '4. Write to file',13,10
	db '5. Run the algorithm',13,10
	db '0. Exit to DOS',13,10
	db 'Input item number',13,10,0
fn	db 80 dup (?); больше 80 символов не получится ввести на одной строке
ibuf	db 4096 dup(?); оба буфера по 4 килобайта
obuf	db 4096 dup(?); надо закрывать всё нулём
msg	db 'Error',13,10,0
frm	db 'Incorrect format',13,10,0; ошибка в алгоритме. Каждая строка, в т.ч. последняя, должна заканчиваться \n - 13, 10
qws	db 'Input file name',13,10,0
inp	db 'Input text. To end input blank line',13,10,0
bye	db 'Good bye!',13,10,0
	end; здесь не содержится ни одной процедуры, поэтому точку входа не объявляем


Файл proc.asm
	.model medium
public	inputline,input,readfile,output,writefile,menu,algorithm
extrn	start:far; объявляем точку входа как внешнюю метку
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
	repne scasb
	neg cx
	dec cx
	dec cx
	jcxz @@ex
	cmp cx,4095
	jbe @@m1
	stc
	jmp short @@ex
@@m1:	mov di,@@ibuf
	mov al,10
	xor bx,bx
@@m2:	push di; сохраняем адреса начала строк
	inc bx
	repne scasb; ищем конец строки - 10
	cmp byte ptr [di-2],13; указатель указывает на начало следующей строки.
	jne @@er
	cmp byte ptr [di-1],10; если последняя строка оборвана, мы тоже можем обнулиться ==> надо проверить корректное завершение строки
	jne @@er
	jcxz @@m3; могли достигнуть конца буфера
	jmp @@m2
@@m3:	mov cx,bx; загрузили количество строк для внешнего цикла
	mov di,@@obuf; настраиваем на начало выходного буфера
@@m4:	pop si; адрес очередной строки
@@m5:	lodsb; считываем символ
	stosb; записали символ
	cmp al,10; если очередной символ - 10, извлекаем очередную строку - очередная итерация внешнего цикла
	jne @@m5
	loop @@m4; посчитали очередную строку
	xor al,al; закрываем результирующие данные
	stosb
	clc; очищаем флаг переноса
	jmp short @@ex
@@er:	shl bx,1; надо восстановить стек, раз произошла ошибка. В bx хранится число строк, которые мы уже записали.
	add sp,bx; восстанавливаем состояние стека до начала работы со строками
	stc; устанавливаем флаг ошибки
@@ex:	pop di
	pop si
	pop cx
	pop bx
	pop ax
	pop bp
	ret
	endp
	end start

