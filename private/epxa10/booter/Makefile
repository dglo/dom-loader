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
#

#
# pick your config file here...
#
CONFIG = config.dom-mb.micron
#CONFIG = config.dom-mb
#CONFIG = config.epxa1

#
# exports...
#
EPXAH = ../../../../epxa10/build/dom-loader/public/booter/epxa.h
PTES = ../../../../epxa10/build/dom-loader/public/booter/pte.S
PLLSRCH = ../../../../epxa10/build/dom-loader/pllsrch

#
# imports...
#
SFIBIN=../../../../epxa10/bin/sfi.bin
KERNELX=../../../public/epxa10/loader/kernel.x

AFLAGS = -mcpu=arm920t
CFLAGS = -Wall -O
CC = gcc
AS = arm-elf-as
LD = arm-elf-ld -N
OBJCOPY = arm-elf-objcopy

AUTOS = mmap.S sdram.S ebi.S pll.S iocontrol.S uart.S pte.S
 
.SUFFIXES: .c .o .S .elf .awk .h

.c.o:
	$(CC) -c $(CFLAGS) $<

.S.o:
	$(AS) $(AFLAGS) -o $*.o $*.S

.awk.S:
	gawk -f common.awk -f $< < $(CONFIG) > $*.S

.awk.h:
	gawk -f common.awk -f $< < $(CONFIG) > $*.h

all: config_files bin

config_files: $(EPXAH) $(PTES)

clean:
	rm -f mempat pattern.mem $(PLLSRCH) epxa.h \
		*.o *.i *.bin *.elf $(AUTOS) *.hex

mempat: mempat.o
	$(CC) -o mempat mempat.o

pattern.mem: mempat
	./mempat > pattern.mem

$(PLLSRCH): pllsrch.o
	@test -d $(@D) || mkdir -p $(@D)
	$(CC) -o $(PLLSRCH) pllsrch.o

ebi.S: ebi.awk $(CONFIG)
pll.S: pll.awk $(CONFIG) $(PLLSRCH)
iocontrol.S: iocontrol.awk $(CONFIG)
uart.S: uart.awk $(CONFIG)
mmap.S: mmap.awk $(CONFIG)
sdram.S: sdram.awk $(CONFIG)

pte.S: pte.awk $(CONFIG)
$(PTES): pte.S
	cp -v pte.S $(PTES)

epxa.h: epxa.awk $(CONFIG)
$(EPXAH): epxa.h
	cp -v epxa.h $(EPXAH)

boot.o : boot.S $(AUTOS) \
	pattern.mem  $(SFIBIN) minimal.bin

boot.elf: boot.o
	$(LD) --script=boot.x -o boot.elf boot.o

minimal.o: minimal.S
	$(CPP) $(CPPFLAGS) -o $*.i $<
	$(AS) $(AFLAGS) -o $*.o $*.i

minimal.elf: minimal.o
	$(LD) --script=$(KERNELX) -o minimal.elf minimal.o

minimal.bin: minimal.elf
	$(OBJCOPY) -O binary minimal.elf minimal.bin

iceboot.hex: boot.elf
	$(OBJCOPY) -O ihex boot.elf iceboot.hex

bin: iceboot.bin boot.elf iceboot.hex
	cp -v iceboot.bin iceboot.bin.gz iceboot.hex ../../../../epxa10/bin

iceboot.bin: boot.elf
	$(OBJCOPY) -O binary boot.elf iceboot.bin

iceboot.bin.gz: iceboot.bin
	gzip -c iceboot.bin > iceboot.bin.gz











