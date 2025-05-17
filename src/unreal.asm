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

	mov eax, 0xffff00ff
	mov ecx, 640 * 480
	mov edx, [0x1028]

.writeloop:
	mov DWORD [edx], eax
	add edx, 4
	sub ecx, 1
	cmp ecx, 0
	jne .writeloop

.loop:
	jmp .loop
