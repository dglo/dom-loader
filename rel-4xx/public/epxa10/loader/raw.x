OUTPUT_FORMAT("elf32-littlearm")
OUTPUT_ARCH(arm)
SECTIONS
{
	. = 0x00400000;
	.text : { *(.text) }
}
