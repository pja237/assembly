#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <sys/timeb.h>
#include <unistd.h>
#include <omp.h>

extern void _asm_search(char *input, char *pattern, char *hitmask, char *output, int outer_loop, int rest);

#define ROWS 1000
#define INPUT_LEN 1000
#define PATTERN_LEN 2

int main(void)
{
    int i;
    struct timeb stop, start;

    FILE *OUTPUT_FILE;

    char pattern[32]={1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1};
    char hitmask[32]={255,255,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};

    char **input_matrix;
    char **output_matrix;

    int il, ol, r, fl;

    int iam, nt;
    int diff;

/* -------------------------------------------------------------------------------- */
/*                      HOUSEKEEPING AND SETUP                                      */
/* -------------------------------------------------------------------------------- */

    il=32-PATTERN_LEN;
    ol=(INPUT_LEN-PATTERN_LEN)/il;
    r=(INPUT_LEN-PATTERN_LEN)-(ol*il);
    fl=(ol+1)*32; /* FIXED_LENGTH */
    printf("il=%d ol=%d r=%d fl=%d\n",il,ol,r,fl);

    strncpy(pattern, "TC", 2);

    srand(time(NULL));

    /* omp_set_num_threads(4); */

    input_matrix=(char **) calloc(sizeof (char*), ROWS);
    output_matrix=(char **) calloc(sizeof (char*), ROWS);

/* -------------------------------------------------------------------------------- */
/*                      MATRIX INITIATION LOOP                                      */
/* -------------------------------------------------------------------------------- */

        ftime(&start);
        printf("generate_input(%d x %d) in all threads started...", ROWS, INPUT_LEN);

#pragma omp parallel for private(iam, nt)
    for(i=0; i<ROWS; i++) {
        int j;
        iam = omp_get_thread_num();
        nt = omp_get_num_threads();
        /* printf("Thread %d of %d. Initializing %d ROW.\n", iam, nt, i); */

        input_matrix[i]=(char *) calloc(sizeof(char), fl); /* using FIXED_LENGHT NOW */
        output_matrix[i]=(char *) calloc(sizeof(char), fl); /* using FIXED_LENGHT NOW */

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

        ftime(&stop);
        diff = (int) (1000.0 * (stop.time - start.time) + (stop.millitm - start.millitm));
        printf("generate_input(%d x %d) in all threads finished in %u ms\n", ROWS, INPUT_LEN, diff);

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
/*                      _ASM_SEARCH LOOP                                            */
/* -------------------------------------------------------------------------------- */
        ftime(&start);
        printf("_asm_search(%d x %d) in all threads started...", ROWS, INPUT_LEN);

#pragma omp parallel for private(iam, nt)
    for(i=0; i<ROWS; i++) {
        iam = omp_get_thread_num();
        nt = omp_get_num_threads();
        /* printf("Thread %d of %d. Working on %d ROW.\n", iam, nt, i); */

            _asm_search(input_matrix[i], pattern, hitmask, output_matrix[i], ol, r);
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
        printf("_asm_search(%d x %d) in all threads finished in %u ms\n", ROWS, INPUT_LEN, diff);

/* -------------------------------------------------------------------------------- */

/* -------------------------------------------------------------------------------- */
/*                      DUMP TO SCREEN                                              */
/* -------------------------------------------------------------------------------- */
    /*
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
    */
/* -------------------------------------------------------------------------------- */

/* -------------------------------------------------------------------------------- */
/*                      DUMP TO FILE                                                */
/* -------------------------------------------------------------------------------- */
    OUTPUT_FILE=fopen("./caller.out", "w");
    for(i=0; i<ROWS; i++) {
        int j;
        fprintf(OUTPUT_FILE, "INPUT %d : \n",i);
        for(j=0; j<INPUT_LEN; j++) {
            fprintf(OUTPUT_FILE, "%c ", input_matrix[i][j]);
        }
        fprintf(OUTPUT_FILE, "\nOUTPUT %d : \n",i);
        for(j=0; j<INPUT_LEN; j++) {
            fprintf(OUTPUT_FILE, "%d ", output_matrix[i][j]);
        }
        fprintf(OUTPUT_FILE, "\n");
    }
    fclose(OUTPUT_FILE);
/* -------------------------------------------------------------------------------- */

    return 0;
}
