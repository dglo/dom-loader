OBJCOPY := arm-elf-objcopy
LOADER_DIR := ../dom-loader/$(PLATFORM_PUB_ROOT)/loader
RAW_S := $(LOADER_DIR)/raw.S
RAW_X := $(LOADER_DIR)/raw.x
BOOTX := ../dom-loader/$(PLATFORM_PUB_ROOT)/booter/boot.x
KERNEL_X := $(LOADER_DIR)/kernel.x
LD_FLAGS += -N
TEMP = $(@D)/$(*F)-tmp
CREATE_KERNEL_ELF = $(LD) $(LD_FLAGS) --script=$(KERNEL_X) -o $(@) $(LIB_DIR)/crt0.o $(<) $(LOAD_LIBDIRS) $(LOAD_LIBS) $(SYS_LIBS)

LOADER_BINS := $(patsubst %,$(BIN_DIR)/%.bin.gz, $(C_BIN_NAMES))
LOADER_RM_EXES := $(patsubst %,$(BUILD_DIR)/%.$(C_BIN_SUFFIX), $(C_BIN_NAMES))
BIN_EXES := $(filter-out $(LOADER_RM_EXES), $(BIN_EXES)) $(LOADER_BINS)
LOADER_RM_BINS := $(patsubst %,$(BIN_DIR)/%, $(C_BIN_NAMES))
TO_BE_CLEANED := $(filter-out $(LOADER_RM_BINS), $(TO_BE_CLEANED)) $(LOADER_BINS)
