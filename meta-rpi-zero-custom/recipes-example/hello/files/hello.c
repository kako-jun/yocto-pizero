#include <stdio.h>
#include <time.h>

int main(int argc, char *argv[]) {
    time_t now;
    time(&now);

    printf("========================================\n");
    printf("Hello from Raspberry Pi Zero!\n");
    printf("========================================\n");
    printf("Built with Yocto Project\n");
    printf("Current time: %s", ctime(&now));
    printf("========================================\n");

    return 0;
}
