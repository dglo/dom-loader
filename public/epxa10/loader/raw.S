	/* we need a program to load programs from flash
	 * into locations where redboot is currently located.
	 * we use the redboot "g" command to load this program
	 * which copies the binary image in kernel.bin to address
	 * zero.  we then call the routine at address 0
	 */
	.text
	
start_:
	/* r2 has address of hello.bin
	 * r3 has address to load
	 * r4 has end address
	 */
	ldr	r2, =kernel_begin
	ldr	r3, =0
	ldr	r4, =kernel_end

copy_loop:
	ldr	r5, [r2]
	str	r5, [r3]
	add	r2, r2, #0x04
	add	r3, r3, #0x04
	cmp	r2, r4
	blt	copy_loop

	/* flush instruction cache... */
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
	
	/* start executing from "boot" */
	mov	pc, #0

	.data
	.align 4
kernel_begin:
        .incbin BINFILE
kernel_end:
	.align 4

