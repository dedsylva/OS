#pragma once
#include "stdint.h"
#include "disk.h"
// similar to __attribute__((packed)) of gcc 

typedef uint8_t bool;
#define true 1
#define false 0 
 

#pragma pack(push, 1)
 
// Fields from FAT specification for Root Directory
typedef struct {
  uint8_t Name[11];
  uint8_t Attributes;
  uint8_t _Reserved;
  uint8_t CreatedTimeTenths;
  uint16_t CreatedTime;
  uint16_t CreatedDate;
  uint16_t AccessedDate;
  uint16_t FirstClusterHigh;
  uint16_t ModifiedTime;
  uint16_t ModifiedDate;
  uint16_t FirstClusterLow;
  uint32_t Size;
} FAT_DirectoryEntry;

// similar to __attribute__((packed)) of gcc 
#pragma pack(pop)

typedef struct {
	int Handle;
	bool IsDirectory;
	uint32_t Position;
	uint32_t Size;
} FAT_File;

enum FAT_Attributes {
	FAT_ATTRIBUTE_READ_ONLY				= 0X01,
	FAT_ATTRIBUTE_HIDDEN					= 0X02,
	FAT_ATTRIBUTE_SYSTEM					= 0X04,
	FAT_ATTRIBUTE_VOLUME_ID				= 0X08,
	FAT_ATTRIBUTE_DIRECTORY				= 0X10,
	FAT_ATTRIBUTE_ARCHIVE					= 0X20,
	FAT_ATTRIBUTE_LFN							=  FAT_ATTRIBUTE_READ_ONLY | FAT_ATTRIBUTE_HIDDEN | FAT_ATTRIBUTE_SYSTEM | FAT_ATTRIBUTE_VOLUME_ID

};

bool FAT_Initialize(DISK* disk);
FAT_File far* FAT_Open(DISK* disk, const char* path);
uint32_t FAT_Read(DISK* disk, FAT_File far* file, uint32_t byteCount, void* dataOut);
bool FAT_ReadEntry(DISK* disk, FAT_File far* file, FAT_DirectoryEntry* dirEntry);
void FAT_Close(FAT_File far* file);
