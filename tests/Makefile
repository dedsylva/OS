ASM=nasm

SRC_DIR=src
BUILD_DIR=build

image: $(BUILD_DIR)/floppy.img

$(BUILD_DIR)/floppy.img: $(BUILD_DIR)/boot.bin
	cp $(BUILD_DIR)/boot.bin $(BUILD_DIR)/floppy.img
	truncate -s 1440k $(BUILD_DIR)/floppy.img

$(BUILD_DIR)/boot.bin: $(SRC_DIR)/main.asm always
	$(ASM) $(SRC_DIR)/main.asm -f bin -o $(BUILD_DIR)/boot.bin

always:
	mkdir -p $(BUILD_DIR)


.PHONY: image 
