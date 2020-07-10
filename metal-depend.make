# Copyright © 2020 Keith Packard #
# SPDX-License-Identifier: Apache-2.0 #

METAL_DEPEND ?= $(FREEDOM_METAL)/scripts/metal_depend/metal_depend.py
LDSCRIPT_GENERATOR ?= $(FREEDOM_METAL)/../scripts/ldscript-generator/generate_ldscript.py

LDSCRIPT ?= metal.default.lds

#METAL_HDR = metal/machine.h metal/machine/platform.h metal/machine/inline.h metal/machine-inline.h
METAL_HDR = metal/machine/platform.h metal/machine/inline.h metal/machine-inline.h

METAL_FILES = metal.mk $(METAL_HDR) $(LDSCRIPT)

ifneq ($(METAL_FEATURES),)
METAL_FEATURES_FLAG=-f $(METAL_FEATURES)
endif

include $(BSP)/settings.mk

METAL_CFLAGS=-march=$(RISCV_ARCH) -mabi=$(RISCV_ABI) -mcmodel=$(RISCV_CMODEL)

metal.mk: $(DEVICETREE)
	python3 $(METAL_DEPEND) -o $@ -d $^ $(METAL_FEATURES_FLAG) -m $(FREEDOM_METAL)

#metal/machine.h: metal design.dtb
#	freedom-metal_header-generator -d design.dtb -o $@
#
#metal/machine/platform.h: metal/machine design.dtb
#	freedom-bare_header-generator -d design.dtb -o $@
#
#metal/machine-inline.h: metal/machine.h
#
#metal/machine/inline.h: metal/machine
#	echo "#include <metal/machine-inline.h>" > $@

metal:
	mkdir $@

metal/machine:
	mkdir -p $@

#design.dtb: $(DEVICETREE)
#	dtc -I dts -O dtb -o $@ $^

$(LDSCRIPT): $(DEVICETREE)
	$(LDSCRIPT_GENERATOR) -d $(DEVICETREE) -o $@

clean::
	$(RM) $(METAL_FILES)
	$(RM) -r metal
