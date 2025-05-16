OUTPUT_FORMAT(elf32-i386)
OUTPUT_ARCH(i386);
SECTIONS
        {
                . = 0x7c00;
                __start__ = .;
                .text : AT(0x7c00) {
				_start = .;
                                *(.boot)
                                *(.text)
                        }
        }
__end__ = .;
