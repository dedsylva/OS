ASM=nasm
CC=gcc

SRC_DIR=src
TOOLS_DIR=tools
BUILD_DIR=build

.PHONY: all floppy_image kernel bootloader clean always tools_fat

all: floppy_image tools_fat

#
# Floppy Image
#
floppy_image: $(BUILD_DIR)/main_floppy.img

$(BUILD_DIR)/main_floppy.img: bootloader kernel 
	dd if=/dev/zero of=$(BUILD_DIR)/main_floppy.img bs=512 count=2880 #empty file with size 512k
	mkfs.fat -F 12 -n "NBOS" $(BUILD_DIR)/main_floppy.img #create file system with fat12
	dd if=$(BUILD_DIR)/bootloader.bin of=$(BUILD_DIR)/main_floppy.img conv=notrunc #put bootloader in disk
	mcopy -i $(BUILD_DIR)/main_floppy.img $(BUILD_DIR)/kernel.bin "::kernel.bin" #put kernel in disk 
	mcopy -i $(BUILD_DIR)/main_floppy.img test.txt "::test.txt" 
#
# Bootloader
#
bootloader: $(BUILD_DIR)/bootloader.bin

$(BUILD_DIR)/bootloader.bin: always
	$(ASM) $(SRC_DIR)/bootloader/boot.asm -f bin -o $(BUILD_DIR)/bootloader.bin


#
# Kernel 
#
kernel: $(BUILD_DIR)/kernel.bin

$(BUILD_DIR)/kernel.bin: always
	$(ASM) $(SRC_DIR)/kernel/main.asm -f bin -o $(BUILD_DIR)/kernel.bin

#
# Tools
#
tools_fat: $(BUILD_DIR)/tools/fat
$(BUILD_DIR)/tools/fat: always $(TOOLS_DIR)/fat/fat.c
	mkdir -p $(BUILD_DIR)/tools
	$(CC) -g -o $(BUILD_DIR)/tools/fat $(TOOLS_DIR)/fat/fat.c


#
# Always (creates the directory if it doesn't exists
#
always:
	mkdir -p $(BUILD_DIR)


#
# Clean (delete everything in the folder)
#
clean:
	rm -rf $(BUILD_DIR)/*
