CC = gcc  
CFLAGS = -ggdb -Wall -m64

default: mm.asm
	nasm -l mm.lst -g -f elf64 mm.asm  
	#gcc -Wall -m64 -ggdb -o mm.out mm.o
	ld -o mm.out mm.o 

clean:
	rm *.o
	rm *.out
