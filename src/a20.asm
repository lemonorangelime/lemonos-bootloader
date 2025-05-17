bits 32

extern enable_a20
enable_a20:
	in al, 0x92
	or al, 2
	out 0x92, al
	ret

extern test_a20
test_a20:
	mov [0x000800], esi
	mov [0x100800], edi

	mov eax, [0x000800]
	cmp eax, 0x100800
	je .ret

	mov eax, 1
	ret
.ret:
	mov eax, 0
	ret
