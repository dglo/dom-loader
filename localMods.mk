# Add auto-generated include files to list of includes
EPXA_AWK_SEARCH := $(patsubst %,%/epxa.awk, $(PUB_DIRS) $(PVT_DIRS))
AWK_HDRS_SRCS := $(wildcard $(EPXA_AWK_SEARCH))
AWK_HDRS := $(patsubst %.awk,$(BUILD_DIR)/%.$(C_INC_SUFFIX), $(AWK_HDRS_SRCS))
AWK_HDR_TARGETS :=$(subst $(PUB_DIR_NAME)/$(PLATFORM),$(PUB_DIR_NAME), $(subst $(PVT_DIR_NAME)/$(PLATFORM),$(PVT_DIR_NAME), $(AWK_HDRS)))

BUILT_FILES += $(AWK_HDR_TARGETS)

vpath %.awk $(PUB_DIR_NAME)/$(PLATFORM) $(PUB_DIR_NAME) $(PVT_DIR_NAME)/$(PLATFORM) $(PVT_DIR_NAME)

COMMON_AWK_SEARCH := $(patsubst %,%/$(COMMON_AWK), $(PUB_DIRS) $(PVT_DIRS))
AWK_ASBL_SEARCH := $(patsubst %,%/*.awk, $(PUB_DIRS) $(PVT_DIRS))
AWK_ASBL := $(filter-out $(EPXA_AWK_SEARCH) $(COMMON_AWK_SEARCH), $(wildcard $(AWK_ASBL_SEARCH)))
AWK_ASBL_TARGETS := $(patsubst %.awk, $(BUILD_DIR)/%.$(ASBL_SUFFIX), $(AWK_ASBL))

#BUILT_FILES += $(BUILT_ASBL)


