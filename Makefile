ASM=nasm

SRC_DIR=src
BUILD_DIR=build

.PHONY: all floppy_image kernel bootloader clean always

#
# Floppy Image
#
floppy_image: $(BUILD_DIR)/main_floppy.img

$(BUILD_DIR)/main_floppy.img: bootloader kernel 
	dd if=/dev/zero of=$(BUILD_DIR)/main_floppy.img bs=512 count=2880 #empty file with size 512k
	mkfs.fat -F 12 -n "NBOS" $(BUILD_DIR)/main_floppy.img #create file system with fat12
	dd if=$(BUILD_DIR)/bootloader.bin of=$(BUILD_DIR)/main_floppy.img conv=notrunc #put bootloader in disk
	mcopy -i $(BUILD_DIR)/main_floppy.img $(BUILD_DIR)/kernel.bin "::kernel.bin" #put kernel in disk 

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
# Always (creates the directory if it doesn't exists
#
always:
	mkdir -p $(BUILD_DIR)

#
# Cllean (delete everything in the folder)
#
clean:
	rm -rf $(BUILD_DIR)/*
