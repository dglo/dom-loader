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
	.include "pll.S"

	#
	# setup iocr (stripe i/o)
	# 	
	.include "iocontrol.S"

	#
	# setup ebi interface...
	#
	.include "ebi.S"
	
	#
	# setup and initialize sdram... 
	#
	.include "sdram.S"

	#
	# setup and initialize uart
	#
	.include "uart.S"

	#
	# map flash up hi and jump there...
	#
	# map the rest of the epxa registers...
	#
	.include "mmap.S"

	#
	# copy payload to zero, verify and start it up...
	#
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
	
verify_loop:	
	ldr	r5, [r2]
	ldr	r6, [r3]
	cmp	r5, r6
	bne	before_forever
	add	r2, r2, #4
	add	r3, r3, #4

	cmp	r2, r4
	blt	verify_loop

	#ldr	r0, =0x7fffc290
	#ldr	r1, =0x30
	#ldr	r0, [r1]
	#bl	prtreg

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

	ldr	r7, =0x12345678
	ldr	r6, =0x12345678
	
	#
	# set gpo bit 1
	#
	#ldr r0, =0x7fffc150
	#ldr r1, =0x02
	#str r1, [r0]

	ldr	r8, =0x12345678
	ldr	r9, =0xabcdef01
	b forever
	
before_forever:	
	mov	r8, r3
	mov	r9, r0
	
forever:

	# r8 has expected value	
	mov	r0, r8
	bl	prtreg
	
	ldr r0, =1000000
	awhile2:
		sub	r0, r0, #1
		cmp	r0, #0
	bgt awhile2

	# r9 has actual value
	mov	r0, r9
	bl	prtreg

	
	#
	# rts <- pll lock status...  
	#
	# r4 <- pll 1 lock status...
	#
	#ldr	r0, =0x7fffc324
	#ldr	r6, [r0]

	#
	# talk to pld, F15
	#
	# read:
	#   bit 0: alternate flash memory mapping
	#   bit 1: boot from flash
	#   bit 2: init done
	#   bit 3: nConfig
	#
	#ldr r0, =0x5000000f
	#ldr r6, [r0]
	
	#
	# write a character stream...
	#
	#ldr	r7, =0xabcdef01
	#mov	r0, r7
	#bl	prtreg

	ldr r0, =0
	ldr r1, =10000000
	ldr r2, =1
	awhile:
		add r0, r0, r2
		cmp	r0, r1
	blt awhile

	#
	# FIXME:	wait on ahb1 clks...
	#
	# ldr	r0, =0x7fffc328
	# ldr   r2, (160 * 1000 * 1000)
	# ldr	r1, [r0]
	# add	r1, r1, r2
	# lp:
	# ldr   r1, [r0]
	# cmp   r2, r1
	# bhi   lp
	# 
	
	b forever

	#
	# print a register in r0 to the serial port...
	#
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
#	.incbin "../loader/minimal.bin"
	.incbin "../loader/sfi.bin"
#	.incbin "pattern.mem"
payload_end:


