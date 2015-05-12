CC = gcc  
CFLAGS = -ggdb -Wall -m64 -fopenmp 

default: asm_search.asm caller.c 
	nasm -l asm_search.lst -g -f elf64 asm_search.asm  
	$(CC) $(CFLAGS) -o caller asm_search.o caller.c

clean:
	rm *.o
	rm *.lst
	rm caller
