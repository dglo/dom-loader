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
#  6) convert this new executable to motorola "S-rec" format or
#       binary (image) format
#

#
# files we export...
#
KERNELX=../../../public/epxa10/loader/kernel.x
RAWX=../../../public/epxa10/loader/raw.x
RAWS=../../../public/epxa10/loader/raw.S
LIBK=../../../../epxa10/lib/libkernel.a
CRT0=../../../../epxa10/lib/crt0.o

#
# files we import
#
EPXAHD = ../../../../epxa10/build/dom-loader/source
EPXAH = $(EPXAHD)/booter/epxa.h
PTESD = ../../../../epxa10/build/dom-loader/source
PTES = $(PTESD)/booter/pte.S

ARM_HOME = /usr/local
AFLAGS = -mcpu=arm920t  -I$(PTESD)
CPPFLAGS = -I$(EPXAHD)
CFLAGS = -mlittle-endian -mcpu=arm920 -Wall \
	-nostdinc -I$(ARM_HOME)/arm-elf/arm-elf/include \
	-I$(ARM_HOME)/arm-elf/lib/gcc-lib/arm-elf/3.2/include \
	-I../expat/xmlparse \
	-I../../../../stf/public \
	-I../../../../hal/public \
	-I../../../../hal/private/epxa10 \
	-I/usr/local/arm-elf/include \
	$(CPPFLAGS)

CPP = arm-elf-cpp
CC = arm-elf-gcc
AS = arm-elf-as
AR = arm-elf-ar
LD = arm-elf-ld -N
OBJCOPY = arm-elf-objcopy

SYSLIBS = $(ARM_HOME)/arm-elf/arm-elf/lib/libc.a \
	$(ARM_HOME)/arm-elf/lib/gcc-lib/arm-elf/3.2/libgcc.a \
	$(ARM_HOME)/arm-elf/lib/libz.a

.SUFFIXES: .c .o .S .elf .srec .bin .gz

.c.o:
	$(CC) -c $(CFLAGS) $<

.S.o:
	$(CPP) $(CPPFLAGS) -o $*.i $<
	$(AS) $(AFLAGS) -o $*.o $*.i

.elf.srec:
	$(OBJCOPY) -O binary $*.elf $*.bin
	$(CPP) $(CPPFLAGS) -DBINFILE=\"$*.bin\" -o $*-raw.i $(RAWS)
	$(AS) $(AFLAGS) -o $*-raw.o $*-raw.i
	$(LD) --script=$(RAWX) -o $*-raw.elf $*-raw.o
	$(OBJCOPY) -O srec $*-raw.elf $*.srec

.elf.bin:
	$(OBJCOPY) -O binary $*.elf $*.bin
	$(CPP) $(CPPFLAGS) -DBINFILE=\"$*.bin\" -o $*-raw.i $(RAWS)
	$(AS) $(AFLAGS) -o $*-raw.o $*-raw.i
	$(LD) --script=$(RAWX) -o $*-raw.elf $*-raw.o
	$(OBJCOPY) -O binary $*-raw.elf $*.bin

.bin.gz:
	gzip -c $< > $*.gz

all: $(CRT0) $(LIBK) main.gz stfserv.gz menu.gz

clean:
	rm -f *.o *.i *.bin *.elf *.hex *.gz

ICELIBS = ../../../../epxa10/lib/libhal.a ../iceboot/libiceboot.a
KOBJS = crt0.o exceptions.o irq.o uartcomm.o
OBJS = $(KOBJS) main.o

exceptions.o: exceptions.c $(EPXAH)
irq.o: irq.c $(EPXAH)
uartcomm.o: uartcomm.c $(EPXAH)

main_flash.hex: main.elf
	$(OBJCOPY) -O ihex main.elf main_flash.hex

main.elf: $(KOBJS) main.o
	$(LD) --script=$(KERNELX) -o main.elf $(OBJS) $(SYSLIBS)

memtests.o: ../../../../stf/private/stf-apps/memtests.c
	$(CC) -c $(CFLAGS) ../../../../stf/private/stf-apps/memtests.c

$(LIBK) : $(KOBJS)
	$(AR) rv $(LIBK) $(KOBJS)

$(CRT0) : crt0.S $(PTES) $(EPXAH)
	$(CPP) $(CPPFLAGS) -o crt0.i crt0.S
	$(AS) $(AFLAGS) -o $(CRT0) crt0.i


STFELF = ../../../../stf/private/stf-apps/stfserv.elf
MENUELF = ../../../../stf/private/stf-apps/menu.elf

stfserv.elf: $(STFELF) $(KOBJS)
	$(LD) --script=$(KERNELX) -o stfserv.elf $(KOBJS) $(STFELF) $(SYSLIBS)

menu.elf: $(MENUELF) $(KOBJS)
	$(LD) --script=$(KERNELX) -o menu.elf $(KOBJS) $(MENUELF) $(SYSLIBS)


