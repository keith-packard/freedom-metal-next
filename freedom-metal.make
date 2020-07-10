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

include metal.mk

SOURCE ?= .

SOURCE_VPATH ?= $(SOURCE):$(SOURCE)/src

vpath %.c $(SOURCE_VPATH):$(METAL_HELPER_VPATH):$(TARGET_C_VPATH)
vpath %.S $(SOURCE_VPATH):$(METAL_HELPER_VPATH):$(TARGET_S_VPATH)

CC = riscv64-unknown-elf-gcc

LDFLAGS = -nostartfiles -T$(LDSCRIPT)

ABIFLAGS = $(METAL_CFLAGS) -msave-restore

INCFLAGS = -I. -I$(FREEDOM_METAL) -I$(FREEDOM_METAL)/sifive-blocks

OPT ?= -Os -g

CFLAGS = -DMTIME_RATE_HZ_DEF=32768 --specs=$(RISCV_LIBC).specs -fno-common -ffunction-sections -fdata-sections $(OPT) $(ABIFLAGS) $(INCFLAGS) $(LDFLAGS) $(SOURCE_CFLAGS) $(FEATURE_DEFINES)
LIBS = $(SOURCE_LIBS)

SRC_C += $(METAL_HELPER_C) $(TARGET_C) $(wildcard src/*.c)
SRC_S += $(METAL_HELPER_S) $(TARGET_S) $(wildcard src/*.S)
OBJ = $(notdir $(SRC_C:.c=.o)) $(notdir $(SRC_S:.S=.o))
#GEN_HDR = metal/machine.h metal/machine/platform.h metal/machine/inline.h metal/machine-inline.h
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

echo::
	echo $(OBJ)

generate:
	make -C $(FREEDOM_METAL) generate OUTPUT_DIR=$(abspath .) DEVICETREE=$(abspath $(DEVICETREE))