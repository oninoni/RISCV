
firmware.elf: sections.lds start.s firmware.c
	riscv64-unknown-elf-gcc -march=rv32i -Wl,-Bstatic,-T,sections.lds,--strip-debug -ffreestanding -nostdlib -o firmware.elf start.s firmware.c

firmware.bin: firmware.elf
	riscv64-unknown-elf-objcopy -O binary firmware.elf /dev/stdout > firmware.bin

firmware.hex: firmware.bin
	python3 makehex.py $^ 4096 > $@

