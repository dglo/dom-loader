#
# bootstrap
#
# map all registers...
#
# get memory map setup...
#
# load payload...
#

# define Mode_SVC        0x13
# define I_Bit           0x80
# define F_Bit           0x40
	
	.globl _start

	.section .init

_start:
	b	Boot
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
	stmdb	sp!,{r0-r12,lr}

	sub r0, lr, #4
	ldr r0, [r0]
	mvn r1, #0xff000000
	and r0, r0, r1
#	bl CSwiHandler
	ldmia	sp!,{r0-r12,lr}
	movs		pc, lr

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
#	bl	CDabtHandler
	ldmia	sp!,{r0-r12,lr}
	subs	pc,lr,#4

FiqHnd:	
	stmdb	sp!,{r0-r7,lr}
#	bl	CFiqHandler
	ldmia	sp!,{r0-r7,lr}
	subs	pc,lr,#4
		
Boot:
	#
	# FIXME: check chip id register...
	# 

        #
        # first run out of sram
	#
	
	#
	# turn on instruction cache...
	#
	mrc 	p15,0,r0,c1,c0,0
	ldr	r1,=0x1078
	orrs	r0,r0,r1
	mcr 	p15,0,r0,c1,c0,0

	#
	# setup plls...
	#
	.include "booter/pll.S"

	#
	# setup iocr (stripe i/o)
	# 	
	.include "booter/iocontrol.S"

	#
	# setup and initialize uart
	#
	.include "booter/uart.S"

	# print .
	ldr	r1, =0x7fffc290
	ldr	r2, =0x2e
	str	r2, [r1]	

	#
	# setup ebi interface...
	#
	.include "booter/ebi.S"

	# print .
	ldr	r1, =0x7fffc290
	ldr	r2, =0x2e
	str	r2, [r1]	
		
	#
	# setup and initialize sdram... 
	#
	.include "booter/sdram.S"

	# print .
	ldr	r1, =0x7fffc290
	ldr	r2, =0x2e
	str	r2, [r1]	

	#
	# map flash up hi and jump there...
	#
	# map the rest of the epxa registers...
	#
	.include "booter/mmap.S"

	# print .
	ldr	r1, =0x7fffc290
	ldr	r2, =0x2e
	str	r2, [r1]	
	
	#
	# copy payload to zero, verify and start it up...
	#
	mov	r10, #0
	ldr	r1, =0x40000000
	ldr	r2, =payload_begin
	add	r2, r2, r1
	ldr	r3, =0
	ldr	r4, =payload_end
	add	r4, r4, r1

copy_loop:
	ldr	r5, [r2]
	str	r5, [r3]
	add	r2, r2, #4
	add	r3, r3, #4
	cmp	r2, r4
	blt	copy_loop

	ldr	r1, =0x40000000
	ldr	r2, =payload_begin
	add	r2, r2, r1
	ldr	r3, =0
	ldr	r4, =payload_end
	add	r4, r4, r1

	#
	# registers used in this loop:
	#
	# r2, r3 pointers to memory
	# r4 end pointer
	# r5, r6: expected, actual values
	#
verify_loop:	
	ldr	r5, [r2]
	ldr	r6, [r3]
	cmp	r5, r6
	beq	verify_next

	#
	# mark that verify failed...
	#
	mov	r10, #1
	
	#
	# print expected, actual, address...
	#
	# prtreg uses r1-r5, save what we need (r2-r4)...
	#
	mov	r7, r2
	mov	r8, r3
	mov	r9, r4
	
	mov	r0, r5
	bl	prtreg

	#
	# wait for this to drain...
	#
	ldr r0, =1000000
wait0:
	sub	r0, r0, #1
	cmp	r0, #0
	bgt	wait0

	# 
	# actual value read...
	#	
	mov	r0, r6
	bl	prtreg

	#
	# wait for this to drain...
	#
	ldr r0, =1000000
wait1:
	sub	r0, r0, #1
	cmp	r0, #0
	bgt	wait1

	#
	# address of sdram...
	#
	mov	r0, r8
	bl	prtreg	

	#
	# wait for this to drain...
	#
	ldr r0, =1000000
wait2:
	sub	r0, r0, #1
	cmp	r0, #0
	bgt	wait2

	#
	# restore registers...
	#
	mov	r2, r7
	mov	r3, r8
	mov	r4, r9
	
verify_next:
	add	r2, r2, #4
	add	r3, r3, #4
	cmp	r2, r4
	blt	verify_loop

	cmp	r10, #0
	bne	beenhere
	
verify_ok:
	# print .
	ldr	r1, =0x7fffc290
	ldr	r2, =0x2e
	str	r2, [r1]	

	#
	# disable instruction cache...
	#
	# clears former flash (now stale) mappings at zero
	#
	mrc    p15,0,r1,c1,c0,0
	bic    r1,r1,#0x1000
	mcr    p15,0,r1,c1,c0,0
	mov    r1,#0
	mcr    p15,0,r1,c7,c5,0
	nop
	nop
	nop
	nop
	nop
	nop
	
	#
	# load some registers for 
	# testing afterwards...
	#	
	ldr	r0, =0x7fffc290
	ldr	r1, =0x30
	
	mov	pc, #0
	nop

beenhere:	
	b beenhere

	#
	# helper routines...
	#
	
	#
	# print a register in r0 to the serial port...
	#
	# uses registers r1-r5
prtreg:
	ldr	r2, =28
	ldr	r3, =0x37
	ldr	r4, =0x30
	ldr	r5, =0x7fffc290
nextnib:
	mov	r1, r0, lsr r2
	and	r1, r1, #0xf
	cmp     r1, #0xa
	blt     digit
	add	r1, r1, r3
	str	r1, [r5]
	b	chknext
digit:
	add	r1, r1, r4
	str	r1, [r5]
chknext:
	sub	r2, r2, #4
	cmps	r2, #0
	bge	nextnib

	ldr r1, =0x0d
	str r1, [r5]

	ldr r1, =0x0a
	str r1, [r5]

	mov	pc, lr
	
	.ltorg	

	.align	4
payload_begin:
	.incbin BINFILE
payload_end:


