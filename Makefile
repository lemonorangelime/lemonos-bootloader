SOURCES := $(wildcard src/*.asm)
OBJS := $(subst src/,build/,$(SOURCES:%.asm=%.o))

default: mkdir build

mkdir:
	mkdir -p build

clean:
	rm -rf build

build/%.o: src/%.asm
	nasm -felf $^ -o $@

build: $(OBJS)
	ld -m elf_i386 $^ -T src/link.ld -o build/bootloader.o
	objcopy -O binary build/bootloader.o disk.img

qemu:
	qemu-system-i386 -cpu host -enable-kvm -fda disk.img -serial stdio -vga std -machine acpi=on -boot adc -m 8M
