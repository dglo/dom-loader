struct fis_image_desc {
   unsigned char name[16];      /* Null terminated name */
   void         *flash_base;    /* Address within FLASH of image */
   void         *mem_base;      /* Address in memory where it executes */
   unsigned long size;          /* Length of image */
   void         *entry_point;   /* Execution entry point */
   unsigned long data_length;   /* Length of actual data */
   unsigned char _pad[256-(16+4*sizeof(unsigned long)+3*sizeof(void *))];
   unsigned long desc_cksum;    /* Checksum over image descriptor */
   unsigned long file_cksum;    /* Checksum over image data */
};

struct fis_image_desc *fis_lookup(const char *name);
void fis_list(void);

