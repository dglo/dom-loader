$(BUILD_DIR)/$(PUB_ROOT)/%.h : %.awk $(CONFIG_FILE)
	@test -d $(@D) || mkdir -p $(@D)
	$(GAWK) -f $(<D)/$(COMMON_AWK) -f $(<)  < $(CONFIG_FILE) > $(@D)/$(*F).h

$(BUILD_DIR)/$(PUB_ROOT)/%.S: %.awk $(CONFIG_FILE)
	@test -d $(@D) || mkdir -p $(@D)
	$(GAWK) -f $(<D)/$(COMMON_AWK) -f $(<)  < $(CONFIG_FILE) > $(@D)/$(*F).S

$(BUILD_DIR)/$(PUB_ROOT)/booter/pll.S: booter/pll.awk $(HOST_BUILD_DIR)/pllsrch
	@test -d $(@D) || mkdir -p $(@D)
	(cd $(<D); $(GAWK) -f $(COMMON_AWK) -f $(*F).awk  < $(CONFIG_AWK) > $(*F).S)
	mv $(<D)/$(*F).S $(@D)/$(*F).S

$(HOST_BUILD_DIR)/pllsrch : private/epxa10/booter/pllsrch.c
	@test -d $(@D) || mkdir -p $(@D)
	$(HOST_CC) -o $(@) $(<)

$(HOST_BUILD_DIR)/mempat : private/epxa10/booter/mempat.c
	@test -d $(@D) || mkdir -p $(@D)
	$(HOST_CC) -o $(@) $(<)

$(BUILD_DIR)/crt0.o : crt0.S $(BUILD_DIR)/$(PUB_ROOT)/booter/pte.S $(BUILD_DIR)/$(PUB_ROOT)/booter/epxa.h
	$(CPP) $(CPP_FLAGS) -o $(*F).i $(<)
	$(AS) $(A_FLAGS) $(INC_PATHS) -o $(@) $(*F).i
	@rm $(*F).i

$(BUILD_DIR)/%.o: %.S
	$(CPP) $(CPP_FLAGS) -o $(*F).i $(<)
	$(AS) $(A_FLAGS) -o $(@) $(*F).i
	@rm $(*F).i

$(BUILD_DIR)/%.elf : $(BUILD_DIR)/%.o
	$(LD) --script=$(KERNELX) -o $(@) $(<)

$(LIB_DIR)/crt0.o : $(BUILD_DIR)/crt0.o
	cp $(<) $(@)

$(LIB_DIR)/pattern.mem : $(HOST_BUILD_DIR)/mempat
	./$(<) > $(@)

$(LIB_DIR)/%.bin : $(BUILD_DIR)/%.elf
	@test -d $(@D) || mkdir -p $(@D)
	$(OBJCOPY) -O binary $(<) $(@)
