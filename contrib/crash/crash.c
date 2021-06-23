#include<stdio.h>
#include<string.h>

int main(int argc, char *argv[]) {
    if(argc == 2) {
        if(strcmp(argv[1], "-V") == 0) {
            printf("1.32.0-0.2.crash.el8");
            return 0;
        }
    }
    int *a;
    int b = *a;
}
