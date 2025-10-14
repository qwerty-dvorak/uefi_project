# Makefile for building and running multiple UEFI asm sources.
#
# Each asm in src/*.asm gets its own build subfolder:
#   build/<name>/<name>.o
#   build/<name>/<name>.efi
#   build/<name>/fat.img
#
# Usage:
#   make                # build all images
#   make <name>         # build only that image (e.g. make bootloader)
#   make run            # run default 'main' image
#   make run bootloader # run image named 'bootloader'
#   make run NAME=bootloader  # alternative
#
# Requirements: nasm, lld-link, qemu-system-x86_64, mtools (mmd/mcopy), mkfs.fat, dd

OVMF_CODE = /usr/share/edk2/x64/OVMF_CODE.4m.fd
OVMF_VARS_SRC = /usr/share/edk2/x64/OVMF_VARS.4m.fd

ASSEMBLER = nasm
AFLAGS    = -f win64
LINKER    = lld-link
LFLAGS    = -subsystem:efi_application -entry:efi_main

SRC_DIR   = src
BUILD_DIR = build

ASM_SRCS  = $(wildcard $(SRC_DIR)/*.asm)
NAMES     = $(patsubst $(SRC_DIR)/%.asm,%,$(ASM_SRCS))

OVMF_VARS = $(BUILD_DIR)/my_ovmf_vars.fd

.PHONY: all run clean $(NAMES)

# default: build all images
all: $(foreach n,$(NAMES),$(BUILD_DIR)/$(n)/fat.img)

# Allow "make run bootloader" or "make run NAME=bootloader"
EXTRA_GOALS := $(filter-out run,$(MAKECMDGOALS))
RUN_NAME   := $(or $(firstword $(EXTRA_GOALS)),$(NAME))
RUN_NAME   := $(if $(RUN_NAME),$(RUN_NAME),main)

run: $(BUILD_DIR)/$(RUN_NAME)/fat.img
	@echo "Starting QEMU with image: $(BUILD_DIR)/$(RUN_NAME)/fat.img"
	@qemu-system-x86_64 \
		-drive if=pflash,format=raw,readonly=on,file=$(OVMF_CODE) \
		-drive if=pflash,format=raw,file=$(OVMF_VARS) \
		-drive file=$(BUILD_DIR)/$(RUN_NAME)/fat.img,format=raw

# per-name build rules
# (1) assemble + (2) link to .efi (generated per target)
define BUILD_rules
$(BUILD_DIR)/$(1)/$(1).o: $(SRC_DIR)/$(1).asm
	@echo "Assembling $$< -> $$@"
	@mkdir -p $$(dir $$@)
	@$$(ASSEMBLER) $$(AFLAGS) -o $$@ $$<

$(BUILD_DIR)/$(1)/$(1).efi: $(BUILD_DIR)/$(1)/$(1).o
	@echo "Linking $$< -> $$@"
	@$$(LINKER) $$(LFLAGS) -out:$$@ $$<

$(BUILD_DIR)/$(1)/fat.img: $(BUILD_DIR)/$(1)/$(1).efi $(OVMF_VARS)
	@echo "Creating FAT image for $(1) ..."
	@mkdir -p $$(dir $$@)
	@dd if=/dev/zero of=$$@ bs=1M count=64 >/dev/null 2>&1
	@mkfs.fat -F 32 $$@ >/dev/null 2>&1
	@echo "Copying EFI application to default boot path..."
	@mmd -i $$@ ::/EFI >/dev/null 2>&1 || true
	@mmd -i $$@ ::/EFI/BOOT >/dev/null 2>&1 || true
	@# ensure the built .efi exists before attempting to copy
	@if [ ! -f $(BUILD_DIR)/$(1)/$(1).efi ]; then \
		echo "Error: $(BUILD_DIR)/$(1)/$(1).efi not found"; \
		rm -f $$@; \
		exit 1; \
	fi
	@mcopy -o -i $$@ $(BUILD_DIR)/$(1)/$(1).efi ::/EFI/BOOT/BOOTX64.EFI
endef

$(foreach n,$(NAMES),$(eval $(call BUILD_rules,$(n))))

# writable copy of OVMF vars (single file)
$(OVMF_VARS):
	@mkdir -p $(BUILD_DIR)
	@cp $(OVMF_VARS_SRC) $(OVMF_VARS)

# allow building a single image by name: make bootloader
$(NAMES): %: $(BUILD_DIR)/%/fat.img ;

clean:
	@echo "Cleaning up build files..."
	@rm -rf $(BUILD_DIR)