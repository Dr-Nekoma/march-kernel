LLD := ld

src/kernel.o: $(wildcard src/*)
	mlton -link-opt '-static' -default-ann 'allowFFI true' -keep o src/main.sml

clean:
	rm -f asm/*.o asm/*.bin
	rm -f src/*.o src/main src/*.c

asm/boot.o: $(wildcard asm/*.asm)
	cd asm; nasm boot.asm -f elf64 -o boot.o

img.bin: asm/boot.o link.ld
	$(LLD) main.0.o main.1.o asm/boot.o -T link.ld --oformat binary -o img.bin

run: img.bin
	qemu-system-x86_64 -fda img.bin
