/*
 * crt0.S
 *
 * Copyright (c) Altera Corporation 2002.
 * All rights reserved.
 *
 * This file defines the function _start, which is the entry point for the 
 * image. This is called by the Altera boot loader once the boot loader 
 * has initialised the EPXA10, and loaded the image into RAM.
 *
 * _start performs the initialisation for the C run time environment, and 
 * then calls main().
 *
 * The c initialisation includes:
 * 1. Turn on the instruction cache
 * 2. Turn on the instruction cache and MMU, see below for details on the 
 *    mapping
 * 3. Setup the stack for all modes
 * 4. Clear BSS
 * 5. Initialise the UART
 * 6. Switch to User mode with IRQ's enabled, FIQs disabled
 * 7. Branch to main
 *
 */
#include "booter/epxa.h"

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
	 */
#define RAM_Limit       (MEMORY_SIZE/2) /* we get half, fpga gets half... */
#define SVC_Stack	RAM_Limit	/* 8K SVC stack at top of memory */
#define IRQ_Stack	RAM_Limit-8192	/* followed by  1k IRQ stack */
#define ABT_Stack	IRQ_Stack-1024	/* followed by  1k ABT stack */
#define FIQ_Stack	ABT_Stack-1024	/* followed by	1k FIQ stack */
#define UNDEF_Stack	FIQ_Stack-1024	/* followed by	1k UNDEF stack */
#define USR_Stack	UNDEF_Stack-1024	/* followed by  USR stack */

	.section .init
				
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
	bl	CUdefHandler
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
	bl      CSwiHandler
	ldmia	sp!,{r1-r12,lr}
	movs	pc, lr /* r14? */

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
	mov	r0, sp
	bl	CDabtHandler
	ldmia	sp!,{r0-r12,lr}
	subs	pc,lr,#4

FiqHnd:
	stmdb	sp!,{r0-r7,lr}
	bl	CFiqHandler
	ldmia	sp!,{r0-r7,lr}
	subs	pc,lr,#4

Boot:
	/* Turn on the instruction cache */
	mrc	p15,0,r0,c1,c0,0
	ldr	r1,=0x1078
	orrs	r0,r0,r1
	mcr	p15,0,r0,c1,c0,0

	/* set all domains to be manager, except domain 1 */
	LDR	r0,=0xFFFFFFF7
	MCR	p15,0,r0,c3,c0,0

	/* Enable the MMU and DCache 
	 */
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

	/* Now change to User mode, and set up User mode stack. */
	/*
	msr     cpsr_c, #Mode_USR | I_Bit | F_Bit
	ldr     sp, =USR_Stack
	*/
	
	/* clear the frame pointer */
	mov fp, #0

	/* clear bss */
	ldr r0, =__bss_start__
	mov r1, #0
	ldr r2, =__bss_end__
	sub r2, r2, r0
	bl memset

	/* Enter SVC mode and use the USR stack pointer */
	msr     cpsr_c, #Mode_SVC | F_Bit /* interrupts on */
	ldr     sp, =USR_Stack

	/* call the c entry point */
	bl	main

	/* Loop forever, just in case we return from main */
finished:
	b finished

	/* Place the literal table here */
	.ltorg

	/* Align the page table on a 16kb boundary...
	 */
	.align 14
page_table:
	.include "booter/pte.S"





