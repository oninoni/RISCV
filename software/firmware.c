#include <stdint.h>

#define LED (*(volatile uint16_t *)0x00010000)

void delay() {
    for (int i = 0; i < 1000; i++);
}

int main() {
    while (1) {
        for (int i = 0; i < 16; i++) {
            LED = 1 << i;
            delay();
        }
    }
}