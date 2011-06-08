#
# pll.awk, generate code to program
# the sdram pll (pll2)...
#
# uses the config file to get the correct
# parameters...
#
BEGIN {
  ahb1 = 0;
  external = 0;
  regs = 0;
  cpld = 0;
}

/^REGISTERS/ {
  regs = numericValue($2);
}

/^AHB1/ {
  ahb1 = numericValue($2);
}

/^SDRAM_CLK/ {
  sdram = numericValue($2);
}

/^EXTERNAL/ {
  external = numericValue($2);
}

/^DEVICE/ {
  device = $2;
}

/^EBI2_MAP/ {
   cpld = numericValue($2);
}

/^EBI0_MAP/ {
   ebi0_paddr = numericValue($2);
}

/^PTE/ {
   paddr = numericValue($3);
   if ( paddr == ebi0_paddr && $7 == "NCNB" ) {
      flash_ctl_pte = numericValue($2);
      flash_ctl_size = numericValue($4) * 1024*1024;
   }
}

$1 ~ /^MEM_SIZE$/ {
   memsz = numericValue($2);
}

/^STACK_LOCATION/ {
    stackloc = numericValue($2);
}

END {
   printf("/* epxa.h, automatically generated by epxa.awk...\n */\n");
   printf("#ifndef EPXA_HEADER\n#define EPXA_HEADER\n\n");
   
   if (regs!=0) printf("#define REGISTERS 0x%x\n", regs);
   if (ahb1!=0) printf("#define AHB1 %u\n", ahb1);
   if (cpld!=0) printf("#define CPLD_ADDR 0x%x\n", cpld);

   if (flash_ctl_pte!=0) {
      printf("#define FLASH_CTL_START_ADDR 0x%x\n", flash_ctl_pte);
      printf("#define FLASH_CTL_END_ADDR 0x%x\n", 
	     flash_ctl_pte + flash_ctl_size);
   }

   if (memsz!=0) {
      printf("#define MEMORY_SIZE (%d*1024*1024)\n", memsz);
   }

   if (stackloc!=0) {
       printf("#define EPXA_STACK_LOCATION 0x%08x\n", stackloc);
   }

   if (external!=0) printf("#define EXTERNAL_CLK %d\n", external);

   printf("#define EPXA_HAS_SDRAM %d\n", (sdram!=0) ? 1 : 0);
   
   printf("\n#endif\n");
}



