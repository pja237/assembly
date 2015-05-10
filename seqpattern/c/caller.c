#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <sys/timeb.h>


extern char* _asm_search(char *input, char *pattern, char *hitmask, int inner_loop, int outer_loop, int rest);

/* #define INPUT_LEN 51 */

/* 301 WORKS, 302 SEGFAULTS? */
/* #define INPUT_LEN 302 */
#define INPUT_LEN 100000000
#define PATTERN_LEN 2

#define INNER_LOOP 32-PATTERN_LEN
#define OUTER_LOOP (INPUT_LEN-PATTERN_LEN)/(INNER_LOOP)
#define REST (INPUT_LEN-PATTERN_LEN)-(OUTER_LOOP*INNER_LOOP)

int main(void)
{
    int i;
    struct timeb stop, start;

    char *input;
    char pattern[32]={1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1};
    char hitmask[32]={255,255,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
    char *asm_ret;

    int il, ol, r, fl;

    il=32-PATTERN_LEN;
    ol=(INPUT_LEN-PATTERN_LEN)/il;
    r=(INPUT_LEN-PATTERN_LEN)-(ol*il);
    fl=(ol+1)*32; /* FIXED_LENGTH */
    printf("il=%d ol=%d r=%d fl=%d\n",il,ol,r,fl);

    /* input=(char *) calloc(sizeof(char), 51); */
    /* strncpy(input, "ATCNNTCAAATCANGTCGCATATBGCATCACXCCATCACNTCNGGCTATCN", 51); */
    strncpy(pattern, "TC", 2);


    /* random input generator */

    /* BUG 302! if REST==0 or REST<PATTERN_LEN then we shouldn't be pulling more memory into register after the last OUTER_LOOP */
    /* how to deal with that? */
    /* A) round input here to be multiple of 32 and fill that with Ns ? */
    /* B) do something?! in asm_search.asm ... fuck me, that will most likely lead to a clusterfuck of new bugs :S */
    /* C) do the REST-test here and send rest=0 to asm, there put if rest==0: goto end! */

    /* attempt 1. */
    /* 1. round input to 32 byte multiple */
    /* 2. fill difference with 0s */

    srand(time(NULL));
    /* input=(char *) calloc(sizeof(char), INPUT_LEN); */
    input=(char *) calloc(sizeof(char), fl); /* using FIXED_LENGHT NOW */

    /* A = 0, C = 1, T = 2, G = 3, N = 4 */

    for(i=0; i<INPUT_LEN; i++) {
        int r = rand();
        switch(r%5) {
            case 0: *(input+i)='A';
                    break;
            case 1: *(input+i)='C';
                    break;
            case 2: *(input+i)='T';
                    break;
            case 3: *(input+i)='G';
                    break;
            case 4: *(input+i)='N';
                    break;
        }
    }

/*
    printf("Randomly generated input:\n");
    for(i=0; i<fl; i++) {
        printf("%c ",*(input+i));
    }
    printf("\n");
*/

    /* If the class is INTEGER, the next available register of the sequence %rdi, %rsi, %rdx, %rcx, %r8 and %r9 is used */
    /* 6 parameters */
    /*                    rdi     rsi     rdx        rcx         r8       r9 */
    /* asm_ret=_asm_search(input, pattern, hitmask, INNER_LOOP, OUTER_LOOP, REST); */
    ftime(&start);
        asm_ret=_asm_search(input, pattern, hitmask, il, ol, r);
    ftime(&stop);
    int diff;
    diff = (int) (1000.0 * (stop.time - start.time) + (stop.millitm - start.millitm));
    printf("asm_ret(%d) time: %u ms\n", INPUT_LEN, diff);

/*
    printf("asm_search() returned:\n");
    for(i=0; i<INPUT_LEN; i++) {
        printf("%d ", asm_ret[i]);
    }
    printf("\n");
*/

    return 0;
}
