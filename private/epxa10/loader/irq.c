#include <stdio.h>

static void defaultIRQHandler(void) {
   printf("yikes -- did not catch irq!!!\r\n");
}

static void (*handler)(void) = defaultIRQHandler;
void CIrqHandler(void) { handler(); }
void irqInstall(void (*h)(void) ) { handler = h; }

void CFiqHandler(void) {
   /* This shouldn't happen */
}









