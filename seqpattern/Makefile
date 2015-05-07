CC = gcc  
CFLAGS = -ggdb -Wall -m64

default: sp.asm
	nasm -l sp.lst -g -f elf64 sp.asm  
	#gcc -Wall -m64 -ggdb -o sp.out sp.o
	ld -o sp.out sp.o 

clean:
	rm *.o
	rm *.out
	rm *.lst
