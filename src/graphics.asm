bits 16

extern clear_screen
clear_screen:
	mov al, 0x03
	call set_video_mode
	ret

set_video_mode:
	mov ah, 0
	int 0x10
	ret
