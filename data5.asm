	.model medium
public items, fn, ibuf, obuf, msg, frm, qws, inp, bye, delim
	.data
items db '1. Input from keyboard',13,10
	db '2. Read from file',13,10
	db '3. Output to screen',13,10
	db '4. Write to file',13,10
	db '5. Run the algorithm',13,10
	db '0. Exit to DOS',13,10
	db 'Input item number',13,10,0
fn	db 80 dup (?)
ibuf	db 4096 dup(?)
obuf	db 4096 dup(?)
msg	db 'Error',13,10,0
frm	db 'Incorrect format',13,10,0
qws	db 'Input file name',13,10,0
inp	db 'Input text. To end input blank line',13,10,0
bye	db 'Good bye!',13,10,0
delim db ' ,;',13,10, 0
	end