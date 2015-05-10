#include <stdio.h>

extern void test_proof(void);
int polje[5]={ 1,2,3,4,5 };

int main(void) {

    int i;
    test_proof();

    for(i=0; i<5; i++) {
        printf("%d ",polje[i]);
    }

    return 0;
}
