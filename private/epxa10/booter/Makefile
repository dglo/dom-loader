#
# executables for the altera chips go through
# many stages of processing:
#
#  1) compile and link "kernel" images
#  2) link these kernel images with the executable
#       this guy is mapped at location 0
#     a) to flash this directly, convert this to intel
#        hex file format and use exec_flash_programmer...
#  3) create a binary image of this file
#  4) assemble a "raw" header to load this
#  5) link this new executable with the binary image
#  6) convert this new executable to motorola "S-rec" format
#

AFLAGS = -mcpu=arm920t
CFLAGS = -mlittle-endian -mcpu=arm920 -Wall \
	-nostdinc -I/usr/local/arm-elf/arm-elf/include \
	-I/usr/local/arm-elf/lib/gcc-lib/arm-elf/3.2/include \
	-I../expat/xmlparse \
	-I../../../../stf/include

CPP = arm-elf-cpp
CC = arm-elf-gcc
AS = arm-elf-as
LD = arm-elf-ld -N
OBJCOPY = arm-elf-objcopy

SYSLIBS = /usr/local/arm-elf/arm-elf/lib/libc.a \
	/usr/local/arm-elf/lib/gcc-lib/arm-elf/3.2/libgcc.a

.SUFFIXES: .c .o .S .elf .srec .awk .h

.c.o:
	$(CC) -c $(CFLAGS) $<

.S.o:
	$(AS) $(AFLAGS) -o $*.o $*.S

.awk.S:
	awk -f common.awk -f $< < config.dom-mb > $*.S

.awk.h:
	awk -f common.awk -f $< < config.dom-mb > $*.h

.elf.srec:
	$(OBJCOPY) -O binary $*.elf $*.bin
	$(CPP) $(CPPFLAGS) -DBINFILE=\"$*.bin\" -o $*-raw.i raw.S
	$(AS) $(AFLAGS) -o $*-raw.o $*-raw.i
	$(LD) --script=raw.x -o $*-raw.elf $*-raw.o
	$(OBJCOPY) -O srec $*-raw.elf $*.srec

all: main.srec elements.srec sfi.srec stfserv.srec

clean:
	rm -f *.o *.i *.bin *.elf *.srec

KOBJS = crt0.o exceptions.o irq.o uartcomm.o fis.o
OBJS = $(KOBJS) main.o

mempat: mempat.c
	gcc -o mempat -Wall mempat.c

pattern.mem: mempat
	./mempat > pattern.mem

pllsrch: pllsrch.c
	gcc -o pllsrch -O -Wall pllsrch.c

ebi.S: ebi.awk config.dom-mb
pll.S: pll.awk config.dom-mb pllsrch
iocontrol.S: iocontrol.awk config.dom-mb
uart.S: uart.awk config.dom-mb
mmap.S: mmap.awk config.dom-mb
sdram.S: sdram.awk config.dom-mb

epxa.h: epxa.awk

boot.o : boot.S \
	mmap.S sdram.S ebi.S pll.S iocontrol.S uart.S \
	pattern.mem  ../loader/sfi.bin ../loader/minimal.bin

boot.elf: boot.o
	$(LD) --script=boot.x -o boot.elf boot.o

boot_flash.hex: boot.elf
	$(OBJCOPY) -O ihex boot.elf boot_flash.hex

main.srec: main.elf
main_flash.hex: main.elf
	$(OBJCOPY) -O ihex main.elf main_flash.hex

main.elf: $(KOBJS) main.o
	$(LD) --script=kernel.x -o main.elf $(OBJS) $(SYSLIBS)

memtests.o: ../../../../stf/source/stf-apps/memtests.c
	$(CC) -c $(CFLAGS) ../../../../stf/source/stf-apps/memtests.c

SFIOBJS = $(KOBJS) sfi.o memtests.o

sfi.bin: sfi.elf
	$(OBJCOPY) -O binary sfi.elf sfi.bin

sfi.elf: $(SFIOBJS)
	$(LD) --script=kernel.x -o sfi.elf $(SFIOBJS) $(SYSLIBS)

sfi.srec: sfi.elf

elements.elf: $(KOBJS) elements.o
	$(LD) --script=kernel.x -o elements.elf \
		$(KOBJS) elements.o \
		../expat/xmlparse/libexpat.a \
		$(SYSLIBS)

elements.srec: elements.elf

TESTOBJS = memory.o StfEg.o
STFOBJS = $(KOBJS) $(TESTOBJS) stfserv.o stf.o stfDirectory.o
XMLFILES = memory.xml StfEg.xml
STFELF = ../../../../stf/source/stf-apps/stfserv.elf

stfserv.elf: $(STFELF) $(KOBJS)
	$(LD) --script=kernel.x -o stfserv.elf $(KOBJS) $(STFELF)

stfserv.srec: stfserv.elf
