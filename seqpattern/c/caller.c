#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <sys/timeb.h>
#include <unistd.h>
#include <omp.h>


extern char* _asm_search(char *input, char *pattern, char *hitmask, int inner_loop, int outer_loop, int rest);

#define ROWS 10

/* 301 WORKS, 302 SEGFAULTS? */
/* #define INPUT_LEN 302 */
#define INPUT_LEN 500
#define PATTERN_LEN 2

#define INNER_LOOP 32-PATTERN_LEN
#define OUTER_LOOP (INPUT_LEN-PATTERN_LEN)/(INNER_LOOP)
#define REST (INPUT_LEN-PATTERN_LEN)-(OUTER_LOOP*INNER_LOOP)

int main(void)
{
    int i;
    struct timeb stop, start;

    FILE *OUTPUT_FILE;

    char *input;
    char pattern[32]={1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1};
    char hitmask[32]={255,255,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
    char *asm_ret;

    char **input_matrix;
    char **output_matrix;
    char *asm_return[ROWS];

    int il, ol, r, fl;

    int diff;

    il=32-PATTERN_LEN;
    ol=(INPUT_LEN-PATTERN_LEN)/il;
    r=(INPUT_LEN-PATTERN_LEN)-(ol*il);
    fl=(ol+1)*32; /* FIXED_LENGTH */
    printf("il=%d ol=%d r=%d fl=%d\n",il,ol,r,fl);

    /* input=(char *) calloc(sizeof(char), 51); */
    /* strncpy(input, "ATCNNTCAAATCANGTCGCATATBGCATCACXCCATCACNTCNGGCTATCN", 51); */
    strncpy(pattern, "TC", 2);

    int iam, nt;
    /* omp_set_num_threads(4); */
    srand(time(NULL));

    input_matrix=(char **) calloc(sizeof (char*), ROWS);
    output_matrix=(char **) calloc(sizeof (char*), ROWS);

/* -------------------------------------------------------------------------------- */
#pragma omp parallel for private(iam, nt)
    for(i=0; i<ROWS; i++) {
        int j;
        iam = omp_get_thread_num();
        nt = omp_get_num_threads();
        /* printf("Thread %d of %d. Initializing %d ROW.\n", iam, nt, i); */

        input_matrix[i]=(char *) calloc(sizeof(char), fl); /* using FIXED_LENGHT NOW */
        output_matrix[i]=(char *) calloc(sizeof(char), fl); /* using FIXED_LENGHT NOW */

        /* A = 0, C = 1, T = 2, G = 3, N = 4 */

        for(j=0; j<INPUT_LEN; j++) {
            int r = rand();
            switch(r%5) {
                case 0: input_matrix[i][j]='A';
                        break;
                case 1: input_matrix[i][j]='C';
                        break;
                case 2: input_matrix[i][j]='T';
                        break;
                case 3: input_matrix[i][j]='G';
                        break;
                case 4: input_matrix[i][j]='N';
                        break;
            }
        }
        /*
        for(j=0; j<INPUT_LEN; j++) {
            printf("%c ", input_matrix[i][j]);
        }
        printf("\n%d DONE!\n", iam);
        */
        /* sleep(5); */
    }

/* -------------------------------------------------------------------------------- */
/*
    printf("\nBack to master!\n");
    for(i=0; i<ROWS; i++) {
        int j;
        printf("Row %d : ",i);
    for(j=0; j<INPUT_LEN; j++) {
        printf("%c ", input_matrix[i][j]);
    }
        printf("\n");
    }
    printf("\nDONE!\n");
*/
/* -------------------------------------------------------------------------------- */


        ftime(&start);
#pragma omp parallel for private(iam, nt, asm_ret)
    for(i=0; i<ROWS; i++) {
        iam = omp_get_thread_num();
        nt = omp_get_num_threads();
        /* printf("Thread %d of %d. Working on %d ROW.\n", iam, nt, i); */

            asm_return[i]=_asm_search(input_matrix[i], pattern, hitmask, il, ol, r);
            memcpy(output_matrix[i], asm_return[i], INPUT_LEN);
        /*
        for(j=0; j<INPUT_LEN; j++) {
            printf("%c ", input_matrix[i][j]);
        }
        printf("\n%d DONE!\n", iam);
        */
        /* sleep(5); */
    }
        ftime(&stop);
        diff = (int) (1000.0 * (stop.time - start.time) + (stop.millitm - start.millitm));
        printf("_asm_search(%d) in all threads finished in %u ms\n", INPUT_LEN, diff);

/* -------------------------------------------------------------------------------- */
    printf("\nBack to master! Lets check results:\n");
    for(i=0; i<ROWS; i++) {
        int j;
        printf("INPUT %d : \n",i);
    for(j=0; j<INPUT_LEN; j++) {
        printf("%c ", input_matrix[i][j]);
    }
        printf("\nOUTPUT %d : \n",i);
    for(j=0; j<INPUT_LEN; j++) {
        printf("%d ", output_matrix[i][j]);
    }
        printf("\n");
    }
    printf("\nDONE!\n");
/* -------------------------------------------------------------------------------- */

    /* random input generator */

    /* BUG 302! if REST==0 or REST<PATTERN_LEN then we shouldn't be pulling more memory into register after the last OUTER_LOOP */
    /* how to deal with that? */
    /* A) round input here to be multiple of 32 and fill that with Ns ? */
    /* B) do something?! in asm_search.asm ... fuck me, that will most likely lead to a clusterfuck of new bugs :S */
    /* C) do the REST-test here and send rest=0 to asm, there put if rest==0: goto end! */

    /* attempt 1. */
    /* 1. round input to 32 byte multiple */
    /* 2. fill difference with 0s */

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
    diff = (int) (1000.0 * (stop.time - start.time) + (stop.millitm - start.millitm));
    printf("asm_ret(%d) time: %u ms\n", INPUT_LEN, diff);

    OUTPUT_FILE=fopen("./caller.out", "w");
/* printf("asm_search() returned:\n"); */
    for(i=0; i<INPUT_LEN; i++) {
        fprintf(OUTPUT_FILE, "%c ", input[i]);
    }
    fprintf(OUTPUT_FILE, "\n");
    for(i=0; i<INPUT_LEN; i++) {
        fprintf(OUTPUT_FILE, "%d ", asm_ret[i]);
    }
    fprintf(OUTPUT_FILE, "\n");
    printf("\n");
    fclose(OUTPUT_FILE);

    return 0;
}
