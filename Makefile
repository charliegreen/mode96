# ================================ project options
PROJECT := video-testing
GAME    := video-testing
INFO    := gameinfo.properties
DATA_DIR  := data
BUILD_DIR := _build_
GEN_DIR   := _gen_

BIN_DIR := ../../bin

UZEM_RUN_OPTS := -f

AUX_TARGETS := $(GAME).hex # $(GAME).uze $(GAME).lss $(GAME).eep
AUX_DEPS := Makefile $(wildcard $(DATA_DIR)/*)

HERE := $(realpath .)
KERNEL_OPTS := -DVIDEO_MODE=0 -DVIDEO_MODE_PATH=$(HERE)
KERNEL_OPTS += -DVMODE_ASM_SOURCE='"$(HERE)/video.s"' -DVMODE_C_PROTOTYPES='"$(HERE)/video.h"'
KERNEL_OPTS += -DINTRO_LOGO=0 -DSOUND_MIXER=0 -DTRUE_RANDOM_GEN=1
# KERNEL_OPTS += -DCENTER_ADJUSTMENT=0
AUX_LD_FLAGS := # -Wl,--section-start,.noinit=0x800100 -Wl,--section-start,.data=0x800500
AUX_ASMFLAGS := -g -O0

FILES_C := $(shell find . -type f -iname '*.c')
FILES_H := $(shell find . -type f -iname '*.h')

FILE_S_VMODE_ASM_SOURCE := video.s # the file included into uzeboxVideoEngineCore.s as VMODE_ASM_SOURCE
FILES_S := foo.s tiles.s	   # any other assembly files to be linked in

# --------------------------------
FILES_C := $(patsubst ./%,%,$(FILES_C))
FILES_S := $(patsubst ./%,%,$(FILES_S))
AUX_TARGETS := $(patsubst %,$(BUILD_DIR)/%,$(AUX_TARGETS))
DEP_DIR := $(BUILD_DIR)/dep

# ================================ other globals
MCU     := atmega644
CC      := avr-gcc

UZEBOX := ../../uzebox
KERNEL := $(UZEBOX)/kernel

# https://stackoverflow.com/a/8942216/
export PATH := $(PATH):$(UZEBOX)/bin:../bin

TARGET := $(BUILD_DIR)/$(GAME).elf

HEX_FLASH_FLAGS  := -R .eeprom
HEX_EEPROM_FLAGS := -j .eeprom
HEX_EEPROM_FLAGS += --set-section-flags=.eeprom="alloc,load"
HEX_EEPROM_FLAGS += --change-section-lma .eeprom=0 --no-change-warnings

# ================================ build flags
# options common to compile, link, and assembly rules
COMMON := -mmcu=$(MCU)

CFLAGS = $(COMMON)
CFLAGS += -Wall -gdwarf-2 -std=gnu99 -DF_CPU=28636360UL -Os
CFLAGS += -fsigned-char -ffunction-sections -fno-toplevel-reorder
CFLAGS += -MD -MP -MT $(*F).o -MF $(DEP_DIR)/$(@F).d
CFLAGS += -g3
CFLAGS += $(KERNEL_OPTS)

ASMFLAGS = $(COMMON)
ASMFLAGS += $(CFLAGS)
ASMFLAGS += -x assembler-with-cpp -Wa,-gdwarf2
ASMFLAGS += -g3
ASMFLAGS += $(AUX_ASMFLAGS)

LDFLAGS := $(COMMON)
LDFLAGS += -Wl,-Map=$(BUILD_DIR)/$(GAME).map
LDFLAGS += -Wl,-gc-sections
LDFLAGS += $(AUX_LD_FLAGS)

INCLUDES := -I"$(KERNEL)"

# ================================ required objects
FILES_KERNEL := uzeboxVideoEngineCore.s uzeboxSoundEngineCore.s
FILES_KERNEL += uzeboxCore.c uzeboxSoundEngine.c uzeboxVideoEngine.c
FILES_KERNEL := $(patsubst %,$(KERNEL)/%,$(FILES_KERNEL))

# objects that must be built in order to link
OBJECTS := $(notdir $(FILES_KERNEL)) $(FILES_C) $(FILES_S)
OBJECTS := $(patsubst %.c,%.o,$(OBJECTS))
OBJECTS := $(patsubst %.s,%.o,$(OBJECTS))
OBJECTS := $(patsubst %,$(BUILD_DIR)/%,$(OBJECTS))

# ================================ build
.PHONY: all

all: $(TARGET) $(AUX_TARGETS)

# -------------------------------- ensure build dir gets created first
$(BUILD_DIR):
	mkdir $(BUILD_DIR)
	mkdir $(DEP_DIR)
	mkdir $(GEN_DIR)

# order-only prerequisite; OBJECTS don't depend on modification date anymore
$(OBJECTS): $(AUX_DEPS) | $(BUILD_DIR)

# -------------------------------- compile kernel files
$(BUILD_DIR)/%.o: $(KERNEL)/%.c
	@echo "CC $<"
	@$(CC) $(INCLUDES) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/%.o: $(KERNEL)/%.s
	@echo "CC $<"
	@$(CC) $(INCLUDES) $(ASMFLAGS) -c $< -o $@

# -------------------------------- compile or generate game files
$(BUILD_DIR)/%.o: %.c $(FILES_H) $(FILES_S) | $(GEN_DIR)
	@echo "CC $<"
	@$(CC) $(INCLUDES) $(CFLAGS) -c $< -o $@

# We actually DON'T want to build our main assembly file (VMODE_ASM_SOURCE), it'll be #include'd
# straight into the kernel (which is a weird way to do things, but ok)

$(BUILD_DIR)/%.o: %.s | $(GEN_DIR)
	@echo "CC $<"
	@$(CC) $(INCLUDES) $(ASMFLAGS) -c $< -o $@

# This also means we should add kernel dependencies so the kernel gets rebuilt when we modify our
# own code; VMODE_ASM_SOURCE gets #include'd from uzeboxVideoEngineCore.s

$(BUILD_DIR)/uzeboxVideoEngineCore.o:	$(FILE_S_VMODE_ASM_SOURCE)

# TODO: figure out how to get just the C files that actually depend on the inc/h files to have rules
# depending on them
$(GEN_DIR): $(patsubst $(DATA_DIR)/%.png,$(GEN_DIR)/%.inc, \
	$(shell find $(DATA_DIR) -type f -iname '*.png'))

# $(DATA_DIR)/%.png: $(DATA_DIR)/%.map.json
# $(GEN_DIR)/%.inc $(GEN_DIR)/%.h: $(DATA_DIR)/%.png # $(DATA_DIR)/%.map.json
#	$(BIN_DIR)/tile_converter.py $< $(GEN_DIR)
$(GEN_DIR)/%.inc: $(DATA_DIR)/%.png
	gconvert $(DATA_DIR)/font.gconvert.xml
	@echo "*** Gconvert finished ***"
# remove warning about only using video mode 9
	@sed -ni '/^#if/,/^#endif/ d; p' $@
	@echo

# -------------------------------- final targets
$(TARGET): $(OBJECTS)
	@echo "LINK"
	@$(CC) $(LDFLAGS) $(OBJECTS) -o $@

%.hex: $(TARGET)
	avr-objcopy -O ihex $(HEX_FLASH_FLAGS)  $< $@

%.eep: $(TARGET)
	-avr-objcopy $(HEX_EEPROM_FLAGS) -O ihex $< $@ || exit 0

lss: $(TARGET:.elf=.lss)
%.lss: $(TARGET)
	avr-objdump -h -S $< > $@

uze: $(TARGET:.elf=.uze)
%.uze: $(TARGET:.elf=.hex)
	-packrom $< $@ $(INFO)

# ================================ utility rules
.PHONY: clean size run uze asm debug lss
clean:
	-$(RM) -rf $(BUILD_DIR)
	-$(RM) -rf $(GEN_DIR)

UNAME := $(shell sh -c 'uname -s 2>/dev/null || echo not')
AVRSIZEFLAGS := -A $(TARGET)
ifneq (,$(findstring MINGW,$(UNAME)))
AVRSIZEFLAGS := -C --mcu=$(MCU) $(TARGET)
endif

size: $(TARGET)
#	@avr-size $(AVRSIZEFLAGS)
	@avr-size -C --mcu=$(MCU) $(TARGET)
	@avr-size -A $(TARGET)

run: $(BUILD_DIR)/$(GAME).hex
	uzem $(UZEM_RUN_OPTS) $<

run-cuzebox: $(BUILD_DIR)/$(GAME).hex
	cuzebox $<

GEN_ASM_FLAGS := -fverbose-asm
asm: $(patsubst %.c,%.s.GEN,$(FILES_C)) $(FILES_H) $(AUX_DEPS)
%.s.GEN: %.c
	@echo "CC -S $< -o $@"
	@$(CC) $(INCLUDES) $(CFLAGS) -S $(GEN_ASM_FLAGS) -c $< -o $@

# add directive so emacs processes as an asm file, despite .GEN ending
	@sed -i '1s/^/;;; -*- mode: asm -*-\n\n/' $@

dump:	$(TARGET)
	avr-objdump -S -l $< > $@

debug:	$(TARGET) $(TARGET:.elf=.hex)
	uzem -d $(TARGET:.elf=.hex) >/dev/null &
	avr-gdb $(TARGET) -ex "target remote localhost:1284" \
		-x init.gdb

# ================================ add any other dependencies
-include $(wildcard $(DEP_DIR)/*)
