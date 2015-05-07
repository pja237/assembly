CC = gcc  
CFLAGS = -ggdb -Wall -m64

default: sp.asm sp_bits.asm
	nasm -l sp.lst -g -f elf64 sp.asm  
	nasm -l sp_bits.lst -g -f elf64 sp_bits.asm  
	#gcc -Wall -m64 -ggdb -o sp.out sp.o
	ld -o sp.out sp.o 
	ld -o sp_bits.out sp_bits.o 

clean:
	rm *.o
	rm *.out
	rm *.lst
