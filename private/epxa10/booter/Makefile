#
# pick your config file here...
#
#CONFIG = config.dom-mb.micron
#CONFIG = config.dom-mb
CONFIG = config.dom-mb.epxa4
#CONFIG = config.epxa1

AUTOS = mmap.S sdram.S ebi.S pll.S iocontrol.S uart.S pte.S asm.S

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

config_files: $(EPXAH) $(PTES) configboot-epxa.h configboot-pte.S

bin: $(ICEBOOTHEX) $(ICEBOOTBINGZ)

clean:
	rm -f mempat pattern.mem pllsrch epxa.h \
		*.o *.i *.bin *.elf $(AUTOS) *.hex

mempat: mempat.c
	gcc -Wall -o mempat mempat.c

pattern.mem: mempat
	./mempat > pattern.mem

pllsrch: pllsrch.c
	gcc -Wall -o pllsrch pllsrch.c

ebi.S: ebi.awk $(CONFIG)
pll.S: pll.awk $(CONFIG) pllsrch
	gawk -f common.awk -vpllsrch="./pllsrch" -f pll.awk $(CONFIG) > pll.S

iocontrol.S: iocontrol.awk $(CONFIG)
uart.S: uart.awk $(CONFIG)
mmap.S: mmap.awk $(CONFIG)
sdram.S: sdram.awk $(CONFIG)
asm.S: asm.awk $(CONFIG)
pte.S: pte.awk $(CONFIG)
$(PTES): pte.S
	cp -v pte.S $(PTES)

epxa.h: epxa.awk $(CONFIG)
$(EPXAH): epxa.h
	cp -v epxa.h $(EPXAH)

configboot-epxa.h: epxa.awk config.dom-mb.configboot
	gawk -f common.awk -f epxa.awk < config.dom-mb.configboot > \
		configboot-epxa.h

configboot-pte.S: pte.awk config.dom-mb.configboot
	gawk -f common.awk -f pte.awk < config.dom-mb.configboot > \
		configboot-pte.S

boot.o : boot.S $(AUTOS) pattern.mem $(SFIBIN) minimal.bin
	$(CPP) $(CPPFLAGS) -DBINFILE=\"$(SFIBIN)\" -o boot.i boot.S
	$(AS) $(AFLAGS) -I.. -o boot.o boot.i

boot.elf: boot.o
	$(LD) --script=boot.x -o boot.elf boot.o

minimal.o: minimal.S
	$(CPP) $(CPPFLAGS) -o $*.i $<
	$(AS) $(AFLAGS) -o $*.o $*.i

minimal.elf: minimal.o
	$(LD) --script=$(KERNELX) -o minimal.elf minimal.o

minimal.bin: minimal.elf
	$(OBJCOPY) -O binary minimal.elf minimal.bin

$(ICEBOOTHEX): boot.elf
	$(OBJCOPY) -O ihex boot.elf $(ICEBOOTHEX)

iceboot.bin: boot.elf
	$(OBJCOPY) -O binary boot.elf iceboot.bin

$(ICEBOOTBINGZ): iceboot.bin
	gzip -c iceboot.bin > $(ICEBOOTBINGZ)
