CC = gcc  
CFLAGS = -ggdb -Wall -m64

default: fib.asm
	nasm -g -f elf64 fib.asm  
	#gcc -Wall -m64 -ggdb -o fib.out fib.o
	ld -o fib.out fib.o 

clean:
	rm *.o
	rm *.out
