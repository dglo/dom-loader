OBJCOPY := arm-elf-objcopy
KERNELX := $(PLATFORM_PUB_ROOT)/loader/kernel.x

CONFIG_PATH := private/epxa10/booter
CONFIG_FILE := $(CONFIG_PATH)/$(CONFIG_AWK)

# Add auto-generated include files to list of public include
AWK_HDR_SEARCH := $(patsubst %,%/epxa.awk, $(PUB_DIRS) $(PVT_DIRS))
AWK_HDRS_SRCS := $(wildcard $(AWK_HDR_SEARCH))
AWK_HDRS := $(patsubst %.awk,$(BUILD_DIR)/%.$(C_INC_SUFFIX), $(AWK_HDRS_SRCS))
AWK_HDR_TARGETS :=$(subst $(PLATFORM_PUB_ROOT)/$(PLATFORM),$(PUB_ROOT), $(subst $(PVT_ROOT)/$(PLATFORM),$(PUB_ROOT), $(AWK_HDRS)))

# Add auto-generated assembler files to list of public assembler
WAITNS_AWK_SEARCH := $(patsubst %,%/waitns.awk, $(PUB_DIRS) $(PVT_DIRS))
COMMON_AWK_SEARCH := $(patsubst %,%/$(COMMON_AWK), $(PUB_DIRS) $(PVT_DIRS))
PUB_AWK_ASBL_SEARCH := $(patsubst %,%/*.awk, $(PUB_DIRS) $(PVT_DIRS))
PUB_AWK_ASBL_SRCS := $(filter-out $(AWK_HDR_SEARCH) $(COMMON_AWK_SEARCH) $(WAITNS_AWK_SEARCH), $(wildcard $(PUB_AWK_ASBL_SEARCH)))
PUB_AWK_ASBL := $(patsubst %.awk, $(BUILD_DIR)/%.$(ASBL_SUFFIX), $(PUB_AWK_ASBL_SRCS))
PUB_AWK_ASBL_TARGETS :=$(subst $(PLATFORM_PUB_ROOT),$(PUB_ROOT), $(subst $(PVT_ROOT)/$(PLATFORM),$(PUB_ROOT), $(PUB_AWK_ASBL)))

ifeq ("epxa10","$(strip $(PLATFORM))")
  vpath %.awk $(PLATFORM_PUB_ROOT) $(PUB_ROOT) $(PLATFORM_PVT_ROOT) $(PVT_ROOT)
  vpath %.S $(BUILD_PUB_DIRS) $(BUILD_PVT_DIRS) $(PUB_DIRS) $(PVT_DIRS)
  BUILT_FILES += $(AWK_HDR_TARGETS) $(PUB_AWK_ASBL_TARGETS)
  PUB_OBJS += $(patsubst %,$(LIB_DIR)/%, crt0.o pattern.mem minimal.bin)
  OBJS += $(PUB_OBJS) $(BUILD_DIR)/minimal.elf
  TO_BE_CLEANED += $(PUB_OBJS) $(HOST_BIN_DIR)/pllsrch $(HOST_BIN_DIR)/mempat
endif

# THIS IS A FUDGE - due to circulary dependencies between dom-loader and hal. 

INC_PATHS += -I../hal/$(PLATFORM)public -I../hal/public
