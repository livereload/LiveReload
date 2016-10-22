#include <stdio.h>
#include <unistd.h>

#include "livereloadhelper.h"

void status_callback(int conns) {
    printf("Status: conns=%d\n", conns);
}

int main() {
    printf("Starting the server...\n");
    LRNetwStart((GoUintptr)&status_callback);
    for (;;) {
        sleep(2);
        printf("Reloading...\n");
        LRNetwReload("foo.css", NULL, NULL, 0);
    }
    LRNetwWaitExit();
    return 0;
}
