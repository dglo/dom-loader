/* make an include file from a binary file...
 */
#include <stdio.h>

int main() {
  while (1) {
      unsigned char buffer[10];
      const int len = sizeof(buffer);
      int nr = fread(buffer, 1, len, stdin);
      int i;

      if (nr==0) break;
      
      printf("\t.byte\t");
      for (i=0; i<nr; i++) 
	printf("0x%02x%s", buffer[i], (i==len-1) ? "\n" : ", ");
      for (i=nr; i<len; i++) 
	printf("0x00%s", (i==len-1) ? "\n" : ", ");
  }
  fflush(stdout);
}
