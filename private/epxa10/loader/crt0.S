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

/* System memory locations */

#define RAM_Limit	EXC_SPSRAM_BLOCK1_BASE + EXC_SPSRAM_BLOCK1_SIZE

#define SVC_Stack	RAM_Limit	    /* 8K SVC stack at top of memory */
#define IRQ_Stack	RAM_Limit-8192	    /* followed by  1k IRQ stack */
#define ABT_Stack	IRQ_Stack-1024	    /* followed by  1k ABT stack */
#define FIQ_Stack		ABT_Stack-1024		/* followed by	1k FIQ stack */
#define UNDEF_Stack		FIQ_Stack-1024		/* followed by	1k UNDEF stack */
#define USR_Stack	UNDEF_Stack-1024    /* followed by  USR stack */

	.globl _start

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

_start:
	b   Boot
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
	bl	CUdefHandler
	ldmia	sp!,{r0-r12,lr}
	subs	pc,lr,#4

SwiHnd:
	stmdb	sp!,{r0-r12,lr}

    /*
     * put the swi argument in r0 and call
     * CSwiHandler
     */

    sub r0, lr, #4
    ldr r0, [r0]
    mvn r1, #0xff000000
    and r0, r0, r1
	bl CSwiHandler
	ldmia	sp!,{r0-r12,lr}
	movs		pc, lr

IrqHnd:
	stmdb	sp!,{r0-r12,lr}
	bl	CIrqHandler
	ldmia	sp!,{r0-r12,lr}
	subs	pc,lr,#4

PabtHnd:
	stmdb	sp!,{r0-r12,lr}
	bl	CPabtHandler
	ldmia	sp!,{r0-r12,lr}
	subs	pc,lr,#4

DabtHnd:
	stmdb	sp!,{r0-r12,lr}
	bl	CDabtHandler
	ldmia	sp!,{r0-r12,lr}
	subs	pc,lr,#4

FiqHnd:
	stmdb	sp!,{r0-r7,lr}
	bl	CFiqHandler
	ldmia	sp!,{r0-r7,lr}
	subs	pc,lr,#4

Boot:
#if 1
	ldr	r0, =(0x80000000)
	mov	r1, #1
	str	r1, [r0]
#endif

	/* Turn on the instruction cache */

	mrc	p15,0,r0,c1,c0,0
	ldr		r1,=0x1078
	orrs	r0,r0,r1
	mcr	p15,0,r0,c1,c0,0

	/* Setup the page table for the MMU */
	ldr	r0,=page_table
	bl		SetupPageTable

	/* set all domains to be manager, except domain 1 */
	LDR	r0,=0xFFFFFFF7
	MCR	p15,0,r0,c3,c0,0

#if 1
	ldr	r0, =(0x80000000)
	mov	r1, #2
	str	r1, [r0]
#endif

	/* Enable the MMU and DCache */
	LDR	r0,=page_table
	MCR	p15,0,r0,c2,c0,0   /* set TTB address */

	MRC	p15,0,r0,c1,c0,0
	ORR	r0,r0,#5	 /* enable DCache and MMU */
	MCR	p15,0,r0,c1,c0,0

	/* Initialise stack pointer registers */

	/* Enter SVC mode and set up the SVC stack pointer */

    msr     cpsr_c, #Mode_SVC | I_Bit | F_Bit /* No interrupts */
    ldr     sp, =SVC_Stack

	/* Enter IRQ mode and set up the IRQ stack pointer */

    msr     cpsr_c, #Mode_IRQ | I_Bit | F_Bit /* No interrupts */
    ldr     sp, =IRQ_Stack

	/* Enter FIQ mode and set up the FIQ stack pointer */

    msr     cpsr_c, #Mode_FIQ | I_Bit | F_Bit /* No interrupts */
    ldr     sp, =FIQ_Stack

	/* Enter UNDEF mode and set up the UNDEF stack pointer */

	msr	cpsr_c, #Mode_UNDEF | I_Bit | F_Bit /* No interrupts */
	ldr	sp, =UNDEF_Stack

	/* Enter ABT mode and set up the ABT stack pointer */

	msr	cpsr_c, #Mode_ABT | I_Bit | F_Bit /* No interrupts */
	ldr	sp, =ABT_Stack

	/* clear the frame pointer */

	mov fp, #0

	/* clear bss */

	ldr r0, =__bss_start__
	mov r1, #0
	ldr r2, =__bss_end__
	sub r2, r2, r0

	bl memset

	/* configure the UART to support stdio */

	bl uart_init

    /* Now change to User mode, and set up User mode stack. */

    msr     cpsr_c, #Mode_USR | F_Bit
    ldr     sp, =USR_Stack

	/* call the c entry point */

	bl main

	/* Loop forever, just in case we return from main */

finished:
	b finished


/*
*	Set up the page table
*
*	The parameters are:
*	r0 - base address of the page table
*
*	r1-r5 and r6 are corrupted in this routine
*
*	The MMU is set up in 1Mb sections, mainly because this is the "easiest"
*	example to show
*
*	All cached regions have a 1:1 virtual to physical mapping with
*	write back enabled
*/
SetupPageTable:
	mov	r6, lr
	/*
	* Set all the page table to cached enabled, write back mode,
	* with a one-one mapping between virtual and physical addresses
	*/
	ldr		r1,=0
	ldr		r2,=0x1000
	ldr		r3,=0xc1e	/* Cached, write back */
	bl		SetupSection

	/*
	*	Now set up the regions which require the the cache disabled i.e.
	*	any region with hardware behind it
	*/
	ldr	r3, =0xc12	/* Cache off */

#ifdef EXC_REGISTERS_BASE
	ldr r0,=page_table
	ldr	r1,=EXC_REGISTERS_BASE
	ldr	r2,= EXC_REGISTERS_SIZE
	ldr	r4,=0xfffff		/* Make sure the region is at least 1Mb */
	add	r2,r2,r4
	mov	r2,r2,lsr #20
	bl	SetupSection
#endif /* EXC_REGISTERS_BASE */

#ifdef EXC_PLD_BLOCK0_BASE
	ldr r0,=page_table
	ldr	r1,=EXC_PLD_BLOCK0_BASE
	ldr	r2,= EXC_PLD_BLOCK0_SIZE
	ldr	r4,=0xfffff		/* Make sure the region is at least 1Mb */
	add	r2,r2,r4
	mov	r2,r2,lsr #20
	bl	SetupSection
#endif /* EXC_PLD_BLOCK0_BASE */

#ifdef EXC_PLD_BLOCK1_BASE
	ldr r0,=page_table
	ldr	r1,=EXC_PLD_BLOCK1_BASE
	ldr	r2,= EXC_PLD_BLOCK1_SIZE
	ldr	r4,=0xfffff		/* Make sure the region is at least 1Mb */
	add	r2,r2,r4
	mov	r2,r2,lsr #20
	bl	SetupSection
#endif /* EXC_PLD_BLOCK1_BASE */

#ifdef EXC_PLD_BLOCK2_BASE
	ldr r0,=page_table
	ldr	r1,=EXC_PLD_BLOCK2_BASE
	ldr	r2,= EXC_PLD_BLOCK2_SIZE
	ldr	r4,=0xfffff		/* Make sure the region is at least 1Mb */
	add	r2,r2,r4
	mov	r2,r2,lsr #20
	bl	SetupSection
#endif /* EXC_PLD_BLOCK2_BASE */

#ifdef EXC_PLD_BLOCK3_BASE
	ldr r0,=page_table
	ldr	r1,=EXC_PLD_BLOCK3_BASE
	ldr	r2,= EXC_PLD_BLOCK3_SIZE
	ldr	r4,=0xfffff		/* Make sure the region is at least 1Mb */
	add	r2,r2,r4
	mov	r2,r2,lsr #20
	bl	SetupSection
#endif /* EXC_PLD_BLOCK3_BASE */

	mov	pc,r6


/*
*	Simple routine to fill out the sections in the page table
*
*	The parameters are:
*	r0 - base address of the page table
*	r1 - Start Address
*	r2 - Number of table entries (Size of the region >> 20)
*	r3 - Mask to apply to the Address
*
*	r1-r5 are currupted in this routine
*/
SetupSection:
	ldr		r5,=0
	ldr	r4,=0xfff00000
	and		r1,r1,r4		/* We only care about 1Mb sections so zero the rest */
SetupSectionNext:
	orr		r4,r1,r3
	str		r4,[r0, +r1, lsr #18]
	add		r1,r1,#0x100000
	add		r5,r5,#1
	cmp		r5,r2
	bne		SetupSectionNext
	mov		pc, lr

	/* Place the literal table here */

	.ltorg

/*
* Align the page table on a 16kb boundary, the table below is zero and is filled
* in at run time
*/
.align 14
page_table:
.fill 4096,4,0





