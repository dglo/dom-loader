	/* we need a program to load programs from flash
	 * into locations where redboot is currently located.
	 * we use the redboot "g" command to load this program
	 * which copies the binary image in kernel.bin to address
	 * zero.  we then call the routine at address 0
	 */
	.text

start_:
	mov	r6, lr

	/* start up, turn on led 1...
	 */
	ldr	r0, =0x80000000
	ldr	r1, =0x20
	str	r1, [r0]

	mov	pc, r6

