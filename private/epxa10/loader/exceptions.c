/*
 *	Copyright (c) Altera Corporation 2002.
 *	All rights reserved.
 *
 *	C Exception Handlers
 */
#include <stdio.h>
#include <string.h>

#include "booter/epxa.h"
#include "hal/DOM_MB_hal.h"

static void dcacheEnable(void);
static void dcacheDisable(void);
static void dcacheInvalidateAll(void);
static void icacheEnable(void);
static void icacheDisable(void);
static void icacheInvalidateAll(void);
static int readPrefetchFaultStatusRegister(void);
static int readDataFaultStatusRegister(void);

static int swiwrite(int file, char *ptr, int len);
static int swiread(int file, char *ptr, int len);
static int swierrno = 0;

static int quickHack() {
#if defined(CPLD_ADDR)
   volatile unsigned char *p = (volatile unsigned char *) 0x50000009;
   return *p & 0x80;
#else
   return 0;
#endif
}

static int putstr(const char *s) { return swiwrite(0, (char *) s, strlen(s)); }
static void puthexdigit(int d) {
   char s[2];
   int dd = d&0xf;
   s[1] = 0;
   s[0] = dd + ((dd<10) ? '0' : 'a');
   putstr(s);
}

void CAbtHandler(void) {
   int fsr = readDataFaultStatusRegister();
   putstr("Data abort, domain="); puthexdigit((fsr&0xf0) >> 4);
   putstr(", fault="); puthexdigit(fsr&0xf); putstr(": halted...\r\n");
   while (1) ;
}

void CPabtHandler(void) {
   int fsr = readPrefetchFaultStatusRegister();
   putstr("Prefetch abort, domain="); puthexdigit((fsr&0xf0) >> 4);
   putstr(", fault="); puthexdigit(fsr&0xf); putstr(": halted...\r\n");
   while (1) ;
}

void CDabtHandler(int *regs) {
   char buf[80];
   volatile int i;

   sprintf(buf, "ahb12b_sr (pg 44): ");
   putstr(buf);
   
   for (i=0; i<500000; i++) ;

#if 0
   sprintf(buf, "%08x [addr: %08x]\r\n",
	   *(volatile unsigned *) (REGISTERS + 0x800),
	   *(volatile unsigned *) (REGISTERS + 0x804));
   putstr(buf);
#endif

#if 1
   sprintf(buf, "pldsb_sr (page 45): %08x [addr: %08x]\r\n",
	   *(volatile unsigned *) (REGISTERS + 0x118),
	   *(volatile unsigned *) (REGISTERS + 0x114));
   putstr(buf);
#endif

   putstr("Error data abort\r\nHalted...");
   while (1) ;
}

int CSwiHandler(int swi, int reason, int *block) {
   int ret = -1;
   if (swi == 0x123456) {
      if (reason==0x05) {
	 /* write */
	 ret = swiwrite(block[0], (char *) block[1], block[2]);
      }
      else if (reason==0x06) {
	 /* read */
	 ret = swiread(block[0], (char *) block[1], block[2]);
      }
      else if (reason==0x13) {
	 /* get errno */
	 ret = swierrno;
      }
      else {
	 char buf[128];
	 sprintf(buf, "unhandled swi, reason, block ptr: 0x%02x %p\r\n", 
		 reason, block);
	 swiwrite(0, buf, strlen(buf));
      }
   }
   else {
      swiwrite(0, "Invalid swi\r\n", strlen("Invalid swi\r\n"));
   }
   return ret;
}

void CUdefHandler(void) {
   putstr("Error undefined instruction\r\n");
}

/* swiwrite directs output to the file indicated by 'file'. In this
 * case all output is directed to the UART, regardless of the value
 * of 'file'. This is valid, since file open is not supported - so
 * the only valid file descriptors available are standard out and
 * standard error.
 *
 */
#include "uartcomm.h"
#include "uart00.h"

static void writeSerial(char *ptr, int len) {
   int i;
   
   for (i=0; i<len; i++) {
      while((*UART_TSR(EXC_UART00_BASE) & UART_TSR_TX_LEVEL_MSK)>=15) ;
      *UART_TD(EXC_UART00_BASE) = ptr[i];
   }
}

/* for debugging only! */
void writeSerialDebug(char *ptr) {
   int n = 0;
   while (ptr[n]) n++;
   if (n) writeSerial(ptr, n);
}

static int swiwrite(int file, char *ptr, int len) {
   int i;

   if (file==4064) {
      /* special */
      const char *c[] = {
	 "disable dcache",
	 "enable dcache",
	 "invalidate dcache all",
	 "disable icache",
	 "enable icache",
	 "invalidate icache all",
      };
      const int clen = sizeof(c)/sizeof(c[0]);
      int idx = -1;

      for (i=0; i<clen; i++) {
	 if (len==strlen(c[i]) && memcmp(c[i], ptr, len)==0) {
	    idx = i;
	    break;
	 }
      }
     
      if (idx==0)      { dcacheDisable(); }
      else if (idx==1) { dcacheEnable(); }
      else if (idx==2) { dcacheInvalidateAll(); }
      else if (idx==3) { icacheDisable(); }
      else if (idx==4) { icacheEnable(); }
      else if (idx==5) { icacheInvalidateAll(); }
      else {
	 swiwrite(1, "invalid special file command!\r\n", 31);
      }
   }
   else {
      if (quickHack() || !halIsConsolePresent()) {
	 int ts = 0;

	 /* no serial power, use DOR for comm...
	  *
	  * FIXME: DOR firmware only supports 400 byte
	  * packets for now...
	  */
	 while (ts<len) {
	    const int nleft = (len-ts);
	    const int ns = nleft<4092 ? nleft : 4092;
	    hal_FPGA_TEST_send(0, ns, ptr + ts);
	    ts+=ns;
	 }
      }
      else writeSerial(ptr, len);
   }
   
   return 0;
}

static int readSerial(char *ptr, int len) {
   int nr = 0;
   while (1) { 
      while ((*UART_RSR(EXC_UART00_BASE) & UART_RSR_RX_LEVEL_MSK) && nr<len) {
	 ptr[nr] = *UART_RD(EXC_UART00_BASE);
	 nr++;
      }
      if (nr>0) break;
   }
   return nr;
}

/* Read from a file. This is always interpreted as a read from
 * standard in, regardless of the value of 'file'. Standard in
 * is implemented using the EPXA10 UART.
 */
static int swiread(int file, char *ptr, int len) {
   int nr = 0;

   if (quickHack() || !halIsConsolePresent() ) {
      static char buffer[1024*4];
      static int bi = 0, bl = 0;

      if (bi) {
	 /* data sitting around? */
	 const int nb = bl-bi;
	 const int nc = (nb < len) ? nb : len;
	 memcpy(ptr, buffer + bi, nc);
	 bi+=nc;
	 if (bi>=bl) {
	    bi = bl = 0;
	 }
	 nr = nc;
      }
      else {
	 int type;

	 hal_FPGA_TEST_receive(&type, &bl, buffer);

	 if (bl <= len) {
	    /* whole buffer goes this time... */
	    memcpy(ptr, buffer, bl);
	    nr = bl;
	    bi = bl = 0;
	 }
	 else {
	    memcpy(ptr, buffer, len);
	    bi = len;
	    nr = len;
	 }
      }
   }
   else {
      nr = readSerial(ptr, len);
   }
   
   return len - nr;
}

static void dcacheEnable(void) {
   unsigned _tmp1, _tmp2;
   asm volatile ("mov    %0, #0;"
		 "1: "
		 "mov    %1, #0;"
		 "2: "
		 "orr    r0,%0,%1;"
		 "mcr    p15,0,r0,c7,c14,2;"  /* clean index in DCache */
		 "add    %1,%1,%2;"
		 "cmp    %1,%3;"
		 "bne    2b;"
		 "add    %0,%0,#0x04000000;"  /* get to next index */
		 "cmp    %0,#0;"
		 "bne    1b;"
		 "mcr    p15,0,r0,c7,c10,4;" /* drain the write buffer */
		 : "=r" (_tmp1), "=r" (_tmp2)
		 : "I" (0x20),
		 "I" (0x80)
		 : "r0" /* Clobber list */
		 );
   
   asm volatile ("mov    r1,#0;"
		 "mcr    p15,0,r1,c7,c6,0;" /* flush d-cache */
		 "mcr    p15,0,r1,c8,c6,0;" /* flush DTLB only */
		 :
		 :
		 : "r1" /* clobber list */);
   
   asm volatile("mrc  p15,0,r1,c1,c0,0;"
		"orr  r1, r1,#0x000c;" 
		"mcr  p15,0,r1,c1,c0,0"
		:
		:
		: "r1" /* Clobber list */
		);
}

static void dcacheDisable(void) {
   unsigned _tmp1, _tmp2;
   asm volatile (
		 "mov    %0, #0;"
		 "1: "
		 "mov    %1, #0;"
		 "2: "
		 "orr    r0,%0,%1;"
		 "mcr    p15,0,r0,c7,c14,2;"  /* clean index in DCache */
		 "add    %1,%1,%2;"
		 "cmp    %1,%3;"
		 "bne    2b;"
		 "add    %0,%0,#0x04000000;"  /* get to next index */
		 "cmp    %0,#0;"
		 "bne    1b;"
		 "mcr    p15,0,r0,c7,c10,4;" /* drain the write buffer */
		 : "=r" (_tmp1), "=r" (_tmp2)
		 : "I" (0x20),
		 "I" (0x80)
		 : "r0" /* Clobber list */
		 );
    
   asm volatile ("mov    r1,#0;"
		 "mcr    p15,0,r1,c7,c6,0;" /* flush d-cache */
		 "mcr    p15,0,r1,c8,c6,0;" /* flush DTLB only */
		 :
		 :
		 : "r1" /* clobber list */);

   asm volatile("mrc  p15,0,r1,c1,c0,0;"
		"bic  r1,r1,#0x000c;" /* disable DCache and write buffer  */
		"mcr  p15,0,r1,c1,c0,0;"
		"mov  r1,#0;"
		"mcr  p15,0,r1,c7,c6,0" /* clear data cache */
		:
		:
		: "r1" /* Clobber list */
		);
}

static void dcacheInvalidateAll(void) {
   unsigned _tmp1, _tmp2;
    asm volatile (
        "mov    %0, #0;"
        "1: "
        "mov    %1, #0;"
        "2: "
        "orr    r0,%0,%1;"
        "mcr    p15,0,r0,c7,c14,2;"  /* clean index in DCache */
        "add    %1,%1,%2;"
        "cmp    %1,%3;"
        "bne    2b;"
        "add    %0,%0,#0x04000000;"  /* get to next index */
        "cmp    %0,#0;"
        "bne    1b;"
        "mcr    p15,0,r0,c7,c10,4;" /* drain the write buffer */
        : "=r" (_tmp1), "=r" (_tmp2)
        : "I" (0x20),
	  "I" (0x80)
        : "r0" /* Clobber list */
        );

   asm volatile ("mov    r1,#0;"
		 "mcr    p15,0,r1,c7,c6,0;" /* flush d-cache */
		 "mcr    p15,0,r1,c8,c6,0;" /* flush DTLB only */
		 :
		 :
		 : "r1" /* clobber list */);
}

static void icacheEnable(void) {
   asm volatile (
        "mrc  p15,0,r1,c1,c0,0;"
        "orr  r1,r1,#0x1000;"
        "mcr  p15,0,r1,c1,c0,0"
        :
        :
        : "r1" /* Clobber list */
        );
}

static void icacheDisable(void) {
   asm volatile (
        "mrc    p15,0,r1,c1,c0,0;"
        "bic    r1,r1,#0x1000;" /* disable ICache (but not MMU, etc) */
        "mcr    p15,0,r1,c1,c0,0;"
        "mov    r1,#0;"
        "mcr    p15,0,r1,c7,c5,0;"  /* flush ICache */
        "nop;" /* next few instructions may be via cache    */
        "nop;"
        "nop;"
        "nop;"
        "nop;"
        "nop"
        :
        :
        : "r1" /* Clobber list */
        );
}

static void icacheInvalidateAll(void) {
    /* this macro can discard dirty cache lines (N/A for ICache) */
    asm volatile (
        "mov    r1,#0;"
        "mcr    p15,0,r1,c7,c5,0;"  /* flush ICache */
        "mcr    p15,0,r1,c8,c5,0;"  /* flush ITLB only */
        "nop;" /* next few instructions may be via cache    */
        "nop;"
        "nop;"
        "nop;"
        "nop;"
        "nop;"
        :
        :
        : "r1" /* Clobber list */
        );
}

static int readPrefetchFaultStatusRegister(void) {
   unsigned reg;
   
   asm volatile (
                 "mrc p15, 0, %0, c5, c0, 1;"
                 : "=r" (reg));
   return reg&0xff;
}

static int readDataFaultStatusRegister(void) {
   unsigned reg;
   
   asm volatile (
                 "mrc p15, 0, %0, c5, c0, 0;"
                 : "=r" (reg));
   return reg&0xff;
}


