#include <stdio.h>

static void karltest(unsigned *read_data, int FIFO_SIZE) 
{
   int i;
   
   for(i=0; i<FIFO_SIZE; i++, read_data++)
#if 0
      if (i & 1) *read_data = 0xffffffffL - (1L<<((i-1)%32));
      else      *read_data = 1L<<(i%32);
#else
   *read_data = i;
#endif
}

#define BSZ (1024*32)

int main() {
   static unsigned pattern[BSZ];
   karltest(pattern, BSZ);
   fwrite(pattern, sizeof(unsigned), BSZ, stdout);
   return 0;
}
