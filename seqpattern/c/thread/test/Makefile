CC = gcc  
CFLAGS = -ggdb -Wall -m64 -fopenmp 

default: asm_copy.asm caller.c 
	nasm -l asm_copy.lst -g -f elf64 asm_copy.asm  
	$(CC) $(CFLAGS) -o caller asm_copy.o caller.c

clean:
	rm *.o
	rm *.lst
