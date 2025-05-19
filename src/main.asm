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

	mov [es:bootdrive], dl

	mov sp, 0x7b00

	mov al, 1
	mov cl, 1
	mov bx, 0x7c00

	call readsector
	call readsector
	call readsector
	call readsector

	call clear_screen
	call selector_main

	call boot

int10h_return:
	int 0x10
	ret



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
; VESA.ASM
;

set_vesa_mode:
	mov ax, 0x4f02
	jmp int10h_return

clear_screen:
	xor ah, ah
	mov al, 0x02
	jmp int10h_return

get_vesa_info:
	mov ax, 0x4f01
	jmp int10h_return

set_cursor_pos:
	mov ah, 0x02
	xor bh, bh
	jmp int10h_return

find_vesa_mode:
	xor cx, cx
.start:
	mov di, 0x1000
	call get_vesa_info

	mov al, [es:0x101b]
	cmp al, 0x06
	jne .end

	mov al, [es:0x1019]
	cmp al, 32
	jne .end

	mov ax, [es:0x1012]
	cmp ax, 640
	jne .end

	mov ax, [es:0x1014]
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



;
; REGISTRY.ASM
;

extern bootdrive
bootdrive: dw 0x00

extern selected
selected: db 0x00

extern load_address
load_address: dw 0


;
; DISK.ASM
;

readsector:
	mov ah, 0x02
	mov al, 0x1
	xor ch, ch
	add cl, 1
	xor dh, dh
	add bx, 512
	int 0x13
	ret



;
; KEYBOARD.ASM
;

poll_keyboard:
	xor ah, ah
	int 0x16
	ret


;
; SELECTOR.ASM
;

selector_main:
	call draw_screen

.poll_loop:
	call draw_selector
	call poll_keyboard
	cmp ah, 0x48
	jne .check_down
	call move_up
	jmp .poll_loop

.check_down:
	cmp ah, 0x50
	jne .check_enter
	call move_down
	jmp .poll_loop

.check_enter:
	cmp ah, 0x1c
	call selected_get_addr
	mov ax, [di]
	mov WORD [es:load_address], ax
	ret

move_up:
	mov al, [es:selected]
	cmp al, 0
	je .end
	sub BYTE [es:selected], 1
.end:
	ret

move_down:
	mov al, [es:selected]
	add al, 1

	mov cl, [es:kernels_header]
	cmp al, cl
	je .end
	mov [es:selected], al
.end:
	ret

draw_screen:
	call draw_line

	mov cl, [es:kernels_header]
.entry_loop:
	push cx
	call draw_entry
	pop cx
	sub cl, 1
	jnz .entry_loop

	mov cl, [es:kernels_header]
	mov bl, 23
	sub bl, cl
	mov cl, bl
.empty_loop:
	push cx
	call draw_empty
	pop cx
	sub cl, 1
	jnz .empty_loop

	mov ax, 0xb800
	mov fs, ax
	mov BYTE [fs:0xf9e], '-'

	mov cx, 79
	jmp draw_line_sized

draw_entry:
	push cx
	mov di, entry_starter
	call puts
	pop cx

	xor ax, ax
	mov al, [es:kernels_header]
	sub al, cl

	mov bx, 24
	mul bx
	mov di, kernels_header + 7
	add di, ax
	call puts
	call draw_space

draw_vertline:
	mov al, '|'
	jmp putc

draw_empty:
	call draw_vertline

	mov al, ' '
	mov cx, 78
.loop:
	call putc
	sub cx, 1
	jnz .loop

	jmp draw_vertline

draw_space:
	mov al, ' '
	mov cx, 62
.loop:
	call putc
	sub cx, 1
	jnz .loop
	ret

draw_line:
	mov cx, 80

draw_line_sized:
	mov al, '-'
.loop:
	call putc
	sub cx, 1
	jnz .loop
	ret

selected_get_string:
	mov di, kernels_header + 7
	jmp selected_offset_into



;
; SECTOR END
;

times 440 - ($ - $$) db 0
dd 0
dw 0
times 16 db 0
times 16 db 0
times 16 db 0
times 16 db 0
dw 0xaa55

;  CONTINUED

selected_get_flags:
	mov di, kernels_header + 23
	jmp selected_offset_into

selected_get_addr:
	mov di, kernels_header + 1

selected_offset_into:
	xor ax, ax
	mov bl, [es:selected]
	mov al, 24
	mul bl
	add di, ax
	ret

draw_selector:
	call selected_get_string
	call strlen
	mov dl, al
	add dl, 1

	mov dh, BYTE [es:selected]
	add dh, 1
	jmp set_cursor_pos

entry_starter: db "| ", 0



;
; VESA.ASM (Extended)
;

video_error_string:
	db "ERROR: 640x480 video mode unsupported", 13, 10, 0



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

strlen:
	xor ax, ax
.loop:
	mov bl, [es:di]
	add di, 1
	add ax, 1
	cmp bl, 0
	je .exit
	cmp bl, ' '
	jne .loop
.exit:
	ret

putc:
	mov ah, 0x0e
	xor bh, bh
	mov bl, 0x07
	jmp int10h_return



;
; BOOT.ASM
;

boot:
	mov sp, 0x7b00
	call clear_screen
	xor dx, dx
	call set_cursor_pos

	call selected_get_flags
	mov ax, [di]
	and ax, 0b0001
	cmp ax, 1
	jne boot32

boot16:
	mov ax, [es:load_address]
	add ax, kernels_header
	call ax
	jmp $

boot32:
	call find_vesa_mode
	cmp ax, 1
	je .skip
	mov di, video_error_string
	call puts
	jmp $

.skip:
	xor ax, ax
	mov ds, ax
	lgdt [es:gdt]

	mov eax, cr0
	or al, 1
	mov cr0, eax

	jmp 0x08:unreal_mode



;
; A20.ASM
;

; - 32 bit section
bits 32

enable_a20:
	in al, 0x92
	or al, 2
	out 0x92, al
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

.loop:
        jmp .loop



;
; SECTOR END
;

times 1024 - ($ - $$) db 0

times 1536 - ($ - $$) db 0

times 2048 - ($ - $$) db 0

; - 16 bit section
bits 16

kernels_header:
kernels:
db 0x03
kernel1_header:
dw kernel1 - kernels_header
dd kernel2 - kernel1
db "LemonOS        ", 0
dw 0b0000000000000001
kernel2_header:
dw kernel2 - kernels_header
dd kernel2 - kernel1
db "RoadrunnerOS   ", 0
dw 0b0000000000000001
kernel3_header:
dw kernel3 - kernels_header
dd kernel2 - kernel1
db "Test           ", 0
dw 0b0000000000000001

kernel1:
	mov di, kernel1_string
	call puts
	ret
kernel1_string: db "todo: implement LemonOS", 0
kernel2:
	mov di, kernel2_string
	call puts
	ret
kernel2_string: db "todo: implement RoadrunnerOS", 0
kernel3:
	mov di, kernel3_string
	call puts
	ret
kernel3_string: db "Bootloader working...", 0

