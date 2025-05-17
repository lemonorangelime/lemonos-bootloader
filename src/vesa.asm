bits 16

extern set_vesa_mode
set_vesa_mode:
	mov ax, 0x4f02
	int 0x10
	ret

extern clear_screen
clear_screen:
	mov ah, 0x00
	mov al, 0x02
	int 0x10
	ret

extern get_vesa_info
get_vesa_info:
	mov ax, 0x4f01
	int 0x10
	ret

; lazy init
extern find_vesa_mode
find_vesa_mode:
	mov cx, 0x0000
.start:
	mov di, 0x1000
	call get_vesa_info

	mov al, [0x101b]
	cmp al, 0x06
	jne .end

	mov al, [0x1019]
	cmp al, 32
	jne .end

	mov ax, [0x1012]
	cmp ax, 640
	jne .end

	mov ax, [0x1014]
	cmp ax, 480
	jne .end

	mov bx, cx
	call set_vesa_mode
	mov ax, 1
	ret
.end:
	add cx, 1
	cmp cx, 0x0fff
	jne .start
	mov ax, 0
	ret
