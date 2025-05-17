bits 16

section .boot

extern bootdrive
extern clear_screen
extern set_video_mode
extern set_video_page
extern find_vesa_mode
extern unreal_mode
extern puts

main:
	jmp 0x0000:.fixup
.fixup:
	xor ax, ax
	mov ds, ax
	mov es, ax
	cld
	cli

	mov bx, bootdrive
	mov [es:bx], dl

	mov sp, 0xffff

	mov al, 1
	mov cl, 1
	mov bx, 0x7c00

.readloop:
	call readsector
	je .readloop

	call clear_screen

	call find_vesa_mode
	cmp ax, 1
	je .skip
	mov di, video_error_string
	call puts
	jmp .loop
.skip:

	xor ax, ax
	mov ds, ax
	lgdt [gdt]

	mov eax, cr0
	or al, 1
	mov cr0, eax

	jmp 0x08:unreal_mode
.loop:
	jmp .loop

align 16
gdtbits: ; LemonOS will overwrite this
	dd 0, 0
	dd 0x0000ffff, 0x00cf9a00
	dd 0x0000ffff, 0x00cf9200
	dd 0x0000ffff, 0x00cffa00
	dd 0x0000ffff, 0x00cff200
gdt:
	dw gdt - gdtbits - 1
	dd gdtbits
	dd 0, 0
align 64

video_error_string:
	db "ERROR: 640x480 video mode unsupported", 13, 10, 0

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
