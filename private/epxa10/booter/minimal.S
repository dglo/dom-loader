/*
 * crt0.S
 *
 * Copyright (c) Altera Corporation 2002.
 * All rights reserved.
 *
 * This file defines the function _start, which is the entry point for the image.
 * This is called by the Altera boot loader once the boot loader has initialised
 * the EPXA10, and loaded the image into RAM.
 *
 * _start performs the initialisation for the C run time environment, and then calls
 * main().
 *
 * The c initialisation includes:
 * 1. Turn on the instruction cache
 * 2. Turn on the instruction cache and MMU, see below for details on the mapping
 * 3. Setup the stack for all modes
 * 4. Clear BSS
 * 5. Initialise the UART
 * 6. Switch to User mode with IRQ's enabled, FIQs disabled
 * 7. Branch to main
 *
 */
#include "stripe.h"

#define Mode_USR	0x10
#define Mode_FIQ	0x11
#define Mode_IRQ	0x12
#define Mode_SVC	0x13
#define Mode_ABT	0x17
#define Mode_UNDEF	0x1B
#define Mode_SYS	0x1F /* available on ARM Arch 4 and later */

#define I_Bit		0x80 /* when I bit is set, IRQ is disabled */
#define F_Bit		0x40 /* when F bit is set, FIQ is disabled */

/* System memory locations
#define RAM_Limit	EXC_SPSRAM_BLOCK1_BASE + EXC_SPSRAM_BLOCK1_SIZE
*/
#define RAM_Limit       (0x00800000) /* put stack at end of sdram0... */
	
#define SVC_Stack	RAM_Limit		/* 8K SVC stack at top of memory */
#define IRQ_Stack	RAM_Limit-8192		/* followed by  1k IRQ stack */
#define ABT_Stack	IRQ_Stack-1024		/* followed by  1k ABT stack */
#define FIQ_Stack	ABT_Stack-1024		/* followed by	1k FIQ stack */
#define UNDEF_Stack	FIQ_Stack-1024		/* followed by	1k UNDEF stack */
#define USR_Stack	UNDEF_Stack-1024	/* followed by  USR stack */

/*
 *	If booting from flash the entry point _start is not arrived at immediately after reset
 *	the quartus project file is doing a few things under your feet that you need to be
 *	aware of.
 *
 *	The Excalibur Megawizard generated a file (.sbd) which contains the information about
 *	the setup you requested for your memory map, IO settings, SDRAM settings etc.
 *
 *	This file, along with your hex file and PLD image is converted to an object file, and
 *	compressed in the process.
 *
 *	This object file is linked with Altera's boot code. Altera's boot code then configures
 *	excalibur's registers to give the setup you requested via the MegaWizard, it
 *	uncompresses the PLD image and the hex file and loads them.
 *
 *	So at this point your memory map should be setup and contain the memory you initially
 *	requested.
 *
 *	For more information on this flow please see the document
 *	Toolflow for ARM-Based Embedded Processor PLDs
 */
	.section .init

#	str	r1, [r0]
#	ldr	r0, =0x7fffc290
#	ldr	r1, =0x41
#	str	r1, [r0]
#	ldr	r1, =0x42

#	b	trybranch
#	str	r1, [r0]
#trybranch:
#	str	r1, [r0]
#	str	r1, [r0]
#
#Boot1:
#	str	r1, [r0]
#
#	ldr	r2, =1000000
#awhile1:
#	sub	r2, r2, #1
#	cmp	r2, #0
#	bgt awhile1
	
#	b Boot1

	b       Boot
	b	UdefHnd
	b	SwiHnd
	b	PabtHnd
	b	DabtHnd
	b	Unexpected
	b	IrqHnd
	b	FiqHnd

Unexpected:
	b	Unexpected

UdefHnd:
	stmdb	sp!,{r0-r12,lr}
#	bl	CUdefHandler
	ldmia	sp!,{r0-r12,lr}
	subs	pc,lr,#4

SwiHnd:
	stmdb	sp!,{r1-r12,lr}

	/* r0:	 swi number
	 * r1:	 reason (passed as r0)
	 * r2:	 block pointer (passed as r1)
	 *
         * CSwiHandler
         */
	mov	r2, r1
	mov	r1, r0
	sub	r0, lr, #4
	ldr     r0, [r0]
	mvn	r3, #0xff000000
	and	r0, r0, r3
#	bl      CSwiHandler
	ldmia	sp!,{r1-r12,lr}
	movs	pc, lr /* r14? */

IrqHnd:
	stmdb	sp!,{r0-r12,lr}
#	bl	CIrqHandler
	ldmia	sp!,{r0-r12,lr}
	subs	pc,lr,#4

PabtHnd:
	stmdb	sp!,{r0-r12,lr}
#	bl	CPabtHandler
	ldmia	sp!,{r0-r12,lr}
	subs	pc,lr,#4

DabtHnd:
	stmdb	sp!,{r0-r12,lr}
	mov	r0, sp
#	bl	CDabtHandler
	ldmia	sp!,{r0-r12,lr}
	subs	pc,lr,#4

FiqHnd:
	stmdb	sp!,{r0-r7,lr}
#	bl	CFiqHandler
	ldmia	sp!,{r0-r7,lr}
	subs	pc,lr,#4

Boot:
	str	r1, [r0]

	ldr r2, =1000000
awhile:
	sub	r2, r2, #1
	cmp	r2, #0
	bgt awhile
	
	b Boot
		
	/* Place the literal table here */

	.ltorg

/*
* Align the page table on a 16kb boundary, the table below is zero and is filled
* in at run time
*/
#.align 14
#page_table:
#.fill 4096,4,0





