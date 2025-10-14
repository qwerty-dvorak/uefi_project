#
# Makefile for building and running a UEFI application with QEMU
#

# --- Configuration ---
# Verify these paths match your system's OVMF installation
OVMF_CODE = /usr/share/edk2/x64/OVMF_CODE.4m.fd
OVMF_VARS_SRC = /usr/share/edk2/x64/OVMF_VARS.4m.fd

# Tools and flags
ASSEMBLER = nasm
AFLAGS    = -f win64
LINKER    = lld-link
LFLAGS    = -subsystem:efi_application -entry:efi_main

# Project structure
BUILD_DIR = build
SRC_FILE  = src/main.asm

# Target files
TARGET_OBJ = $(BUILD_DIR)/main.o
TARGET_EFI = $(BUILD_DIR)/main.efi
IMAGE      = $(BUILD_DIR)/fat.img
OVMF_VARS  = $(BUILD_DIR)/my_ovmf_vars.fd

# --- Targets ---

# Phony targets don't represent actual files
.PHONY: all run clean

# Default target: build the bootable disk image
all: $(IMAGE)

# Build and run the project in QEMU
run: all
	@qemu-system-x86_64 \
		-drive if=pflash,format=raw,readonly=on,file=$(OVMF_CODE) \
		-drive if=pflash,format=raw,file=$(OVMF_VARS) \
		-drive file=$(IMAGE),format=raw

# Adding it to systemd-boot 
bootable: $(TARGET_EFI)
	@if [ ! -d /boot/EFI/custom ]; then \
		sudo mkdir -p /boot/EFI/custom; \
		echo "Created /boot/EFI/custom"; \
	else \
		echo "/boot/EFI/custom already exists"; \
	fi
	@sudo cp $(TARGET_EFI) /boot/EFI/custom/main.efi
	@echo "title   My Custom EFI Application" | sudo tee /boot/loader/entries/custom.conf > /dev/null
	@echo "efi     /EFI/custom/main.efi" | sudo tee -a /boot/loader/entries/custom.conf > /dev/null
	@echo "Now reboot the device and select 'My Custom EFI Application' from the boot menu."


# Rule to create the bootable disk image
$(IMAGE): $(TARGET_EFI) $(OVMF_VARS)
	@echo "Creating 64MB FAT32 disk image..."
	@dd if=/dev/zero of=$(IMAGE) bs=1M count=64 >/dev/null 2>&1
	@mkfs.fat -F 32 $(IMAGE) >/dev/null 2>&1
	@echo "Copying EFI application to default boot path..."
	@mmd -i $(IMAGE) ::/EFI >/dev/null 2>&1
	@mmd -i $(IMAGE) ::/EFI/BOOT >/dev/null 2>&1
	@mcopy -o -i $(IMAGE) $(TARGET_EFI) ::/EFI/BOOT/BOOTX64.EFI >/dev/null 2>&1

# Rule to link the .efi file
$(TARGET_EFI): $(TARGET_OBJ)
	@echo "Linking..."
	@$(LINKER) $(LFLAGS) -out:$(TARGET_EFI) $(TARGET_OBJ)

# Rule to assemble the .asm source file
$(TARGET_OBJ): $(SRC_FILE)
	@echo "Assembling..."
	@mkdir -p $(BUILD_DIR)
	@$(ASSEMBLER) $(AFLAGS) -o $(TARGET_OBJ) $(SRC_FILE)

# Rule to create a writable copy of the OVMF variables file
$(OVMF_VARS):
	@mkdir -p $(BUILD_DIR)
	@cp $(OVMF_VARS_SRC) $(OVMF_VARS)

# Rule to clean up all generated files
clean:
	@echo "Cleaning up build files..."
	@rm -rf $(BUILD_DIR)