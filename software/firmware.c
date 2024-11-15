#include <stdint.h>

#define LED (*(volatile uint16_t *)0x00010000)
#define SEG (*(volatile uint32_t *)0x00010004)

#define SW  (*(volatile uint16_t *)0x00010020)
#define BTN (*(volatile uint16_t *)0x00010022)

void delay() {
    for (int i = 0; i < 1000; i++);
}

int main() {
    SEG = 0x0ABCDEF0;

    while (1) {
        LED = SW;
        delay();
    }
}