AFLAGS = -mcpu=arm920t

AS = arm-elf-as
LD = arm-elf-ld --script=raw.x
OBJCOPY = arm-elf-objcopy

all: raw.srec
clean:
	rm -f raw.srec raw.elf *.o 
raw.srec: raw.elf
	$(OBJCOPY) -O srec raw.elf raw.srec

raw.elf: raw.o
	$(LD) -o raw.elf raw.o

raw.o: raw.S
	$(AS) $(AFLAGS) -o raw.o raw.S

mkinc: mkinc.c
	gcc -o mkinc mkinc.c
