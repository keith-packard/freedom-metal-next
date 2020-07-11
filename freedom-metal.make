# Copyright © 2020 Keith Packard #
# SPDX-License-Identifier: Apache-2.0 #

.DEFAULT_GOAL = $(PROGRAM)

ifeq ($(RISCV_LIBC),picolibc)
include $(FREEDOM_METAL)/metal_pico.make
endif

ifeq ($(RISCV_LIBC),nano)
include $(FREEDOM_METAL)/metal_nano.make
endif

include $(FREEDOM_METAL)/metal-depend.make

include metal/metal.mk

include metal/settings.mk

SOURCE ?= .

SOURCE_VPATH ?= $(SOURCE):$(SOURCE)/src:$(SOURCE)/metal:$(SOURCE)/metal/src

vpath %.c $(SOURCE_VPATH):$(METAL_HELPER_VPATH):$(TARGET_C_VPATH)
vpath %.S $(SOURCE_VPATH):$(METAL_HELPER_VPATH):$(TARGET_S_VPATH)

CC = riscv64-unknown-elf-gcc

LDFLAGS = -nostartfiles -T$(LDSCRIPT)

ABIFLAGS = $(METAL_CFLAGS) -msave-restore

INCFLAGS = -I. -Imetal -I$(FREEDOM_METAL) -I$(FREEDOM_METAL)/sifive-blocks

OPT ?= -Os -g

CFLAGS = -DMTIME_RATE_HZ_DEF=32768 --specs=$(RISCV_LIBC).specs -fno-common -ffunction-sections -fdata-sections $(OPT) $(ABIFLAGS) $(INCFLAGS) $(LDFLAGS) $(SOURCE_CFLAGS) $(FEATURE_DEFINES)
LIBS = $(SOURCE_LIBS)

GEN_SRC_C = metal/src/interrupt_handlers.c metal/src/interrupt_table.c
GEN_SRC_S = metal/src/jump_table.S

SRC_C += $(METAL_HELPER_C) $(TARGET_C) $(GEN_SRC_C)
SRC_S += $(METAL_HELPER_S) $(TARGET_S) $(GEN_SRC_S)
OBJ = $(notdir $(SRC_C:.c=.o)) $(notdir $(SRC_S:.S=.o))
GEN_HDR = metal/metal/machine/platform.h
HDR = $(wildcard *.h) $(GEN_HDR)

ifndef quiet

V?=0
# The user has explicitly enabled quiet compilation.
ifeq ($(V),0)
quiet = @printf "  $1 $2 $@\n"; $($1)
endif

# Otherwise, print the full command line.
quiet ?= $($1)

.c.o:
	$(call quiet,CC) -c $(CFLAGS) -o $@ $<

.S.o:
	$(call quiet,CC) -c $(CFLAGS) -o $@ $<
endif

$(PROGRAM): $(OBJ) $(LDSCRIPT)
	$(CC) $(CFLAGS) -o $@ $(OBJ) -Wl,-Map=$(PROGRAM).map $(LIBS)

$(OBJ): $(HDR) 

clean::
	rm -f $(PROGRAM) $(PROGRAM).map *.o
	rm -rf metal

echo::
	echo $(OBJ)


interrupt_handlers.o: metal/src/interrupt_handlers.c
	$(CC) -c $(CFLAGS) -o $@ $<

interrupt_table.o: metal/src/interrupt_table.c
	$(CC) -c $(CFLAGS) -o $@ $<

jump_table.o: metal/src/jump_table.S
	$(CC) -c $(CFLAGS) -o $@ $<

$(GEN_HDR) $(GEN_SRC_C) $(GEN_SRC_S): metal/template_data.log

metal/template_data.log:
	make -C $(FREEDOM_METAL) generate OUTPUT_DIR=$(abspath metal) DEVICETREE=$(abspath $(DEVICETREE))

metal/settings.mk: $(DEVICETREE)
	mkdir -p metal
	python3 $(ESDK_SETTINGS_GENERATOR)/generate_settings.py -t rtl -d $(DEVICETREE) -o $@
