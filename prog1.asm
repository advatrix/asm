; f = (a^2b^3+3(c^2-d^2))/(2e)
.model small
.stack 100h
.486
.data
a dw 3
b dw 2
c dw 6
d dw 4
e dw 33
f dd ?
.code
mov ax, @data
mov ds, ax
mov ax, 2
mul e
push dx
push ax ; pushed 2e as double word
mov ax, d
mul d
mov bx, dx
mov cx, ax ; saved d^2 as bx:cx
mov ax, c
mul c ; saved c^2 as dx:ax
sub ax, cx
sub dx, bx ; saved c^2 - b^2 as dx:ax
movzx ebx, dx ; dx:ax -> ebx
bswap ebx
mov bx, ax ; saved c^2 - b^2 in ebx
mov eax, 3
mul ebx ; saved 3(c^2 - b^2) as edx:eax
push edx
push eax ; pushed 3(c^2 - b^2) as quarter word
mov ax, a
mul ax ; saved a^2 as dx:ax
push dx
push ax ; saved a^2 as double word
mov ax, b
mov bx, ax
mul bx
mul bx ; saved b^3 as dx:ax
movzx ebx, dx
bswap ebx
mov bx, ax ; saved b^3 as ebx
pop eax ; eax = a^2
mul ebx ; saved a^2b^3 as edx:eax
pop ebx 
pop ecx ; 3(...) as ecx:ebx
add edx, ecx
add eax, ebx ; numerator = edx:eax
pop ebx ; denominator = ebx
div ebx
mov f, edx
mov ax, 4c00h
int 21h
end