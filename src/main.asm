bits 16

section .boot

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



;
; GDT.ASM
;

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



;
; PRINTING.ASM
;

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
	xor bh, bh
	mov bl, 0x07
	int 0x10
	ret



;
; VESA.ASM
;

set_vesa_mode:
	mov ax, 0x4f02
	int 0x10
	ret

clear_screen:
	xor ah, ah
	mov al, 0x02
	int 0x10
	ret

get_vesa_info:
	mov ax, 0x4f01
	int 0x10
	ret

find_vesa_mode:
	xor cx, cx
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
	xor ax, ax
	ret

video_error_string:
	db "ERROR: 640x480 video mode unsupported", 13, 10, 0



;
; REGISTRY.ASM
;

extern bootdrive
bootdrive: dw 0x00



;
; DISK.ASM
;

readsector:
	mov ah, 0x02
	mov al, 0x1
	xor ch, ch
	add cl, 1 ; mov cl, 2
	xor dh, dh
	add bx, 512 ; mov bx, 0x7e00
	int 0x13
	ret



; -- 32 bit section --
bits 32

;
; A20.ASM
;

enable_a20:
	in al, 0x92
	or al, 2
	out 0x92, al
	ret

test_a20:
	mov [0x000800], esi
	mov [0x100800], edi

	mov eax, [0x000800]
	cmp eax, 0x100800
	je .ret

	mov eax, 1
	ret
.ret:
	xor eax, eax
	ret



;
; UNREAL.asm
;

unreal_mode:
        mov ax, 16
        mov ds, ax
        mov ss, ax

        mov esp, 0x7000

        call enable_a20
        call test_a20

.loop:
        jmp .loop

times 510 - ($ - $$) db 0
dw 0xaa55
