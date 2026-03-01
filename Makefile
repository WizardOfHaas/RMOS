all: progs-all main

progs-all:
	$(MAKE) -C progs all

main : main.asm
	nasm main.asm -o kern.com -w-reloc-abs-word

install : kern.com
	mkdir -p ./mnt
	sudo mount boot.img ./mnt
	sudo cp startup.bin ./mnt
	sudo umount ./mnt

qemu-test : boot.img
	make
	make install
	qemu-system-i386 -fda boot.img -monitor stdio

dos-test :
	nasm main.asm -o kern.com -Wall
	dosbox -c "mount c: ." -c "c:" kern.com

serial-test :
	nasm main.asm -o kern.com
	python client/send.py kern.com