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

all: $(CRT0) $(LIBK)

clean:
	rm -f *.o *.i *.bin *.elf *.hex *.gz

KOBJS = exceptions.o irq.o
OBJS = $(KOBJS) main.o

exceptions.o: exceptions.c $(EPXAH)
irq.o: irq.c $(EPXAH)

main_flash.hex: main.elf
	$(OBJCOPY) -O ihex main.elf main_flash.hex

main.elf: $(KOBJS) main.o
	$(LD) --script=$(KERNELX) -o main.elf $(OBJS) $(SYSLIBS)

$(LIBK) : $(KOBJS)
	$(AR) rv $(LIBK) $(KOBJS)

$(CRT0) : crt0.S $(PTES) $(EPXAH)
	$(CPP) $(CPPFLAGS) -o crt0.i crt0.S
	$(AS) $(AFLAGS) -o $(CRT0) crt0.i







