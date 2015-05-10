#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern char* _asm_search(char *input, char *pattern, char *hitmask, int inner_loop, int outer_loop, int rest);

#define INPUT_LEN 51
#define PATTERN_LEN 2

#define INNER_LOOP 32-PATTERN_LEN
#define OUTER_LOOP (INPUT_LEN-PATTERN_LEN)/(INNER_LOOP)
#define REST INPUT_LEN - PATTERN_LEN - (OUTER_LOOP*INNER_LOOP)

int main(void)
{

    char *input;
    char pattern[32]={1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1};
    char hitmask[32]={255,255,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
    char *asm_ret;

    input=(char *) calloc(sizeof(char), 51);
    strncpy(input, "ATCNNTCAAATCANGTCGCATATBGCATCACXCCATCACNTCNGGCTATCN", 51);

    /* pattern=(char *) calloc(sizeof(char), 32); */
    strncpy(pattern, "TC", 2);
    /* printf("Pattern = %s \n",pattern); */

    /* hitmask=(char *) calloc(sizeof(char), 32); */
    /* strncpy(hitmask, "XX", 2); */
    /* printf("Hitmask= %s \n",hitmask); */

    /* If the class is INTEGER, the next available register of the sequence %rdi, %rsi, %rdx, %rcx, %r8 and %r9 is used */
    /* 6 parameters */
    /*                    rdi     rsi     rdx        rcx         r8       r9 */
    asm_ret=_asm_search(input, pattern, hitmask, INNER_LOOP, OUTER_LOOP, REST);

    printf("asm_search() returned:\n");
    int i;
    for(i=0; i<INPUT_LEN; i++) {
        printf("%d ", asm_ret[i]);
    }
    printf("\n");

    return 0;
}
