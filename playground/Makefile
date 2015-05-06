CC = gcc  
CFLAGS = -ggdb -Wall -m64

default: play.asm
	nasm -g -f elf64 play.asm  
	gcc -Wall -m64 -ggdb -o play.out play.o
