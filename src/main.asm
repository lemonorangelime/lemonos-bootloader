bits 16

section .boot

extern bootdrive
extern clear_screen
extern puts
main:
	jmp 0x0000:.fixup
.fixup:
	xor ax, ax
	mov ds, ax
	mov es, ax
	cld

	mov al, dl
	push ax

	mov al, 1
	mov cl, 1
	mov bx, 0x7c00
.readloop:
	call readsector
	je .readloop

	pop ax
	mov dl, al

	mov bx, bootdrive
	mov [es:bx], dl

	call clear_screen

	mov di, string
	call puts

.loop:
	jmp .loop

readsector:
	mov ah, 0x02
	mov al, 0x1
	mov ch, 0
	add cl, 1 ; mov cl, 2
	mov dh, 0
	add bx, 512 ; mov bx, 0x7e00
	int 0x13
	ret

times 510 - ($ - $$) db 0
dw 0xaa55

string:
	db "Hello from bootloader!", 13, 10, "I am working", 0
