/* simple fis routines -- copied from redboot...
 *
 */
#include <string.h>

#include "fis.h"

static const struct fis_image_desc *fis_work_block = 
   (const struct fis_image_desc *) 0x40ff0000;
static const int block_size = 0x00010000;

struct fis_image_desc *fis_lookup(const char *name) {
   int i;
   struct fis_image_desc *img = (struct fis_image_desc *) fis_work_block;
   for (i = 0;  i < block_size/sizeof(*img);  i++, img++) {
      if ((img->name[0] != (unsigned char)0xFF) && (strcmp(name, img->name) == 0)) {
	 return img;
      }
   }
   return (struct fis_image_desc *)0;
}

void fis_list(void) {
   int i;
   struct fis_image_desc *img = (struct fis_image_desc *) fis_work_block;
   for (i = 0;  i < block_size/sizeof(*img);  i++, img++) {
      if (img->name[0] != (unsigned char)0xFF) {
	 printf("%-16s  0x%08lX  0x%08lX  0x%08lX  0x%08lX\r\n", 
		img->name, 
		img->flash_base, 
		img->mem_base, 
		img->size, 
		img->entry_point);
      }
   }
}

