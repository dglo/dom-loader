$(BUILD_DIR)/$(PVT_DIR_NAME)/%.h : %.awk
	@test -d $(@D) || mkdir -p $(@D)
	$(GAWK) -f $(<D)/$(COMMON_AWK) -f $<  < $(<D)/$(CONFIG_AWK) > $(@D)/$(*F).h

