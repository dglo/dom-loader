	/* we need a program to load programs from flash
	 * into locations where redboot is currently located.	
	 * we use the redboot "g" command to load this program
	 * which copies the binary image in binimg to 
	 */
	.text

start_:
	ldr	r0, =0x80000000
	ldr	r1, =0x01
	str	r1, [r0]

	/* write a char...
	 */
	ldr	r0, =5 /* sys_write */
	ldr	r1, =1 /* standard out */
	ldr	r2, =buf /* buffer */
	ldr     r3, =1   /* nbytes */
	ldr	r15, =0xef180001 /* magic? */

	/* r2 has address of hello.bin
	 * r3 has address to load
	 * r4 has end address
	ldr	r2, =hello_begin
	ldr	r3, =0
	ldr	r4, =hello_end
	 */

	ldr	r0, =0x80000000
	ldr	r1, =0x02
	str	r1, [r0]

	/*
copy_loop:
	ldr	r5, [r2]
	str	r5, [r3]
	add	r2, r2, #0x4
	cmp	r2, r4
	blt	copy_loop

	ldr	r0, =0x80000000
	ldr	r1, =0x04
	str	r1, [r0]
	*/
	
forever:	
	b	forever
	
	/* start executing from "boot" */
	mov	pc, #0

	.data
	.align 4
hello_begin:
/*	.INCBIN	"hello.bin"*/
/*	.include "hello.inc" */
/*	.word	0x01020304 */

buf:	.byte	'!'
	
hello_end:
	.align 4
