/* setSDRAM.S, setup the SDRAM controller. assume that
 * the 6 mode registers have already been setup and that
 * the cache is already enabled...
 *
 * we:
 *
 */
#include "stripe.h"

.text
	.align	2
	.global setupSDRAM
	.type	setupSDRAM,function

setupSDRAM:
	@ args = -0, pretend = 0, frame = 4
	@ frame_needed = 1, current_function_anonymous_args = 0

	mov	ip,sp
	stmfd	sp!, {fp, ip, lr, pc}
	sub	fp, ip, #4
	sub	sp, sp, #4


	adr	r1, CACHE_THIS_CODE_START
	adr	r2, CACHE_THIS_CODE_END
	adr	r3, CACHE_THIS_CODE2_START
	adr	r4, CACHE_THIS_CODE2_END

SDR_Load_Cache:
	mcr	p15, 0, r1, c7, c13, 1
	add	r1, r1, #8
	cmp	r1, r2
	ble	SDR_Load_Cache

SDR_Load_Cache2:
	mcr	p15, 0, r3, c7, c13, 1
	add	r3, r3, #8
	cmp	r3, r4
	ble	SDR_Load_Cache2

INIT_SDRAM:
	ldr	r2, =0x8000
	ldr	r3, =0xc000
	ldr	r4, =0x8800
	ldr	r5, =0xa000
	ldr	r6, =(EXC_REGISTERS_BASE + 0x328)

CACHE_THIS_CODE_START:
	ldr	r0, =(EXC_REGISTERS_BASE + 0x41C)
	ldr	r1, [r0]
	orr	r1, r1, r2
	str	r1, [r0]
	str	r3, [r0]
	ldr	r9, =63
	bl	WAIT_FUNCTION

	str	r4, [r0]
	ldr	r9, =63
	bl	WAIT_FUNCTION

	str	r4, [r0]
	ldr	r9, =63
	bl	WAIT_FUNCTION

	ldr	r9, =63
	bl	WAIT_FUNCTION

	str	r5, [r0]
	ldr	r9,=63
	bl	WAIT_FUNCTION

CACHE_THIS_CODE_END:

	ldmea	fp, {fp, sp, pc}

CACHE_THIS_CODE2_START:
WAIT_FUNCTION:
	ldr	r7, [r6]
	add	r7, r7, r9

WAIT_LOOP:
	ldr	r8, [r6]
	cmp	r7, r8
	bhi	WAIT_LOOP
	mov	pc, lr
CACHE_THIS_CODE2_END:
