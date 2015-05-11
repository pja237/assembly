#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <sys/timeb.h>
#include <unistd.h>
#include <omp.h>


extern char* _asm_copy(char *input, char *output, int len);

#define ROWS 10
#define INPUT_LEN 80

int main(void)
{
    int i;
    int iam, nt;

    FILE *OUTPUT_FILE;

    char **input_matrix;
    char **output_matrix;


/* -------------------------------------------------------------------------------- */
/*                      HOUSEKEEPING AND SETUP                                      */
/* -------------------------------------------------------------------------------- */


    srand(time(NULL));

    /* omp_set_num_threads(4); */

    input_matrix=(char **) calloc(sizeof (char*), ROWS);
    output_matrix=(char **) calloc(sizeof (char*), ROWS);

/* -------------------------------------------------------------------------------- */
/*                      MATRIX INITIATION LOOP                                      */
/* -------------------------------------------------------------------------------- */

#pragma omp parallel for private(iam, nt)
    for(i=0; i<ROWS; i++) {
        int j;
        iam = omp_get_thread_num();
        nt = omp_get_num_threads();
        /* printf("Thread %d of %d. Initializing %d ROW.\n", iam, nt, i); */

        input_matrix[i]=(char *) calloc(sizeof(char), INPUT_LEN); /* using FIXED_LENGHT NOW */
        output_matrix[i]=(char *) calloc(sizeof(char), INPUT_LEN); /* using FIXED_LENGHT NOW */

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
/*                      _ASM_SEARCH LOOP                                            */
/* -------------------------------------------------------------------------------- */

#pragma omp parallel for private(iam, nt)
    for(i=0; i<ROWS; i++) {
        iam = omp_get_thread_num();
        nt = omp_get_num_threads();
        printf("Thread %d of %d. Working on %d ROW.\n", iam, nt, i);

            _asm_copy(input_matrix[i], output_matrix[i], INPUT_LEN);

        /*
        for(j=0; j<INPUT_LEN; j++) {
            printf("%c ", input_matrix[i][j]);
        }
        */
        printf("\n%d DONE!\n", iam);
        /* sleep(5); */
    }

        printf("_asm_copy() done!\n");

/* -------------------------------------------------------------------------------- */

/* -------------------------------------------------------------------------------- */
/*                      DUMP TO SCREEN                                              */
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
            printf("%c ", output_matrix[i][j]);
        }
        printf("\n");
    }
    printf("\nDONE!\n");
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
            fprintf(OUTPUT_FILE, "%c ", output_matrix[i][j]);
        }
        fprintf(OUTPUT_FILE, "\n");
    }
    fclose(OUTPUT_FILE);

/* -------------------------------------------------------------------------------- */

    return 0;
}
