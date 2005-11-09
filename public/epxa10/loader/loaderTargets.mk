$(BUILD_DIR)/%.elf : $(BUILD_DIR)/%.o $(LIB_OBJS) $(LIB_DIR)/crt0.o $(KERNEL_X)
	$(CREATE_KERNEL_ELF)

$(BUILD_DIR)/%.bin : $(BUILD_DIR)/%.elf $(RAW_S) $(RAW_X)
	@test -d $(@D) || mkdir -p $(@D)
	$(OBJCOPY) -O binary $(<) $(TEMP).bin
	$(CPP) $(CPP_FLAGS) -DBINFILE=\"$(TEMP).bin\" -o $(TEMP).i $(RAW_S)
	$(AS) $(A_FLAGS) $(INC_PATHS) -o $(TEMP).o $(TEMP).i
	$(LD) $(LD_FLAGS) --script=$(RAW_X) -o $(TEMP).elf $(TEMP).o
	$(OBJCOPY) -O binary $(TEMP).elf $(@)
	@rm $(TEMP).bin $(TEMP).i $(TEMP).o $(TEMP).elf

$(BIN_DIR)/%.bin.gz: $(BUILD_DIR)/%.bin
	gzip -c $(<) > $(@)
