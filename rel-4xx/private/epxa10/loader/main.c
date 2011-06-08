#include <stdio.h>
#include <stdlib.h>

#include "booter/epxa.h"

#include "uartcomm.h"

static void decode(int reg) {
   printf("\tbase: %08x, size: %dK, np: %s, en: %d\r\n",
	  reg&0xffffc000, 
	  (1<<(((reg&0xf80)>>7)+1))/1024, 
      (reg&2) ? "yes" : "no",
	  reg&1);
}


/* dump the contents of the mmap registers...
 */
static void dumpmmap(void) {
   printf("sram[0, 1]: %08x %08x\r\n", 
	  *(volatile int *) 0x7fffc090, *(volatile int *) 0x7fffc094);
   decode(*(volatile int *) 0x7fffc090);
   decode(*(volatile int *) 0x7fffc094);

   printf("dpsram[0, 1]: %08x %08x\r\n", 
	  *(volatile int *) 0x7fffc0a0, *(volatile int *) 0x7fffc0a4);
   decode(*(volatile int *) 0x7fffc0a0);
   decode(*(volatile int *) 0x7fffc0a4);

   printf("sdram[0, 1]: %08x %08x\r\n", 
	  *(volatile int *) 0x7fffc0b0, *(volatile int *) 0x7fffc0b4);
   decode(*(volatile int *) 0x7fffc0b0);
   decode(*(volatile int *) 0x7fffc0b4);

   printf("ebio[0, 1, 2, 3]: %08x %08x %08x %08x\r\n", 
	  *(volatile int *) 0x7fffc0c0, *(volatile int *) 0x7fffc0c4,
	  *(volatile int *) 0x7fffc0c8, *(volatile int *) 0x7fffc0cc);
   decode(*(volatile int *) 0x7fffc0c0);
   decode(*(volatile int *) 0x7fffc0c4);
   decode(*(volatile int *) 0x7fffc0c8);
   decode(*(volatile int *) 0x7fffc0cc);

   printf("pld[0, 1, 2, 3]: %08x %08x %08x %08x\r\n", 
	  *(volatile int *) 0x7fffc0d0, *(volatile int *) 0x7fffc0d4,
	  *(volatile int *) 0x7fffc0d8, *(volatile int *) 0x7fffc0dc);
   decode(*(volatile int *) 0x7fffc0d0);
   decode(*(volatile int *) 0x7fffc0d4);
   decode(*(volatile int *) 0x7fffc0d8);
   decode(*(volatile int *) 0x7fffc0dc);
}

#include "fis.h"

int main() {
   dumpmmap();
   return 0;
   
}









