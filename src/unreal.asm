bits 32

extern unreal_mode
extern enable_a20
extern test_a20
unreal_mode:
	mov ax, 16
	mov ds, ax
	mov ss, ax

	mov esp, 0x7000

	call enable_a20
	call test_a20

.loop:
	jmp .loop
