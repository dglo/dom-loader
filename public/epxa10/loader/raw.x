OUTPUT_FORMAT("elf32-littlearm")
OUTPUT_ARCH(arm)
SECTIONS
{
	. = 0x04000000;
	.text : { *(.text) }
	.data : { *(.data) }
	.bss : { *(.bss) }
}
