bits 16

extern puts
extern putc
preputs:
	call putc
puts:
	mov al, [es:di]
	add di, 1
	cmp al, 0
	jne preputs
	ret

putc:
	mov ah, 0x0e
	mov bh, 0
	mov bl, 0x07
	int 0x10
	ret
