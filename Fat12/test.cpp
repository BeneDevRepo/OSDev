#include <iostream>
#include <fstream>
#include <cstdint>

struct __attribute__((packed)) BootSector {
	uint8_t bootJumpIntruction[3]; // jmp short start; nop;

	uint8_t  oem[8]; // 8 Bytes, Content irrelevant
	uint16_t bytesPerSector;
	uint8_t  sectorsPerCluster;
	uint16_t reservedSectors; // number of reserved sectors
	uint8_t  fatCount;
	uint16_t dirEntriesCount;
	uint16_t totalSectors; // 2880 * 512 = 1.44MB
	uint8_t  mediaDescriptorType;
	uint16_t sectorsPerFat;
	uint16_t sectorsPerTrack;
	uint16_t heads;
	uint32_t hiddenSectors;
	uint32_t largeSectors;

	// ===== Extended Boot Record:
	uint8_t driveNumber;
	uint8_t reserved;
	uint8_t signature;
	uint8_t volumeId[4]; // arbitrary 4 byte id
	uint8_t volumeLabel[11]; // arbitrary String padded to 11 bytes
	uint8_t systemId[8]; // padded to 8 bytes
};

struct __attribute__((packed)) DirectoryEntry {
	uint8_t name[11];
	uint8_t attributes;
	uint8_t reserved;

	uint16_t creationTimeTenths;
	uint16_t creationTime;
	uint16_t creationDate;

	uint16_t firstClusterHigh;

	// uint16_t creationTimeTenths;
	uint16_t modifiedTime;
	uint16_t modifiedDate;

	uint16_t firstClusterLow;

	uint32_t size;
};


BootSector bootSector;
uint8_t* fat;
DirectoryEntry* rootDirectory = nullptr;

bool readBootSector(FILE* disk) {
	fread((char*)&bootSector, sizeof(BootSector), 1, disk);
	return true;
}

bool readSectors(FILE* disk, uint32_t lba, uint32_t count, void* out) { // disk, LogicalBlockAddress, numBlocks, output
	bool ok = true;
	ok &= fseek(disk, lba * bootSector.bytesPerSector, SEEK_SET) == 0;
	ok &= fread(out, bootSector.bytesPerSector, count, disk) == count;
	return ok;
}

bool readFat(FILE *disk) {
	fat = new uint8_t[bootSector.sectorsPerFat * bootSector.bytesPerSector];
	return readSectors(disk, bootSector.reservedSectors, bootSector.sectorsPerFat, fat); // FAT begins right after reserved sectors
}

bool readRootDirectory(FILE *disk) {
	fat = new uint8_t[bootSector.sectorsPerFat * bootSector.bytesPerSector];
	return readSectors(disk, bootSector.reservedSectors, bootSector.sectorsPerFat, fat); // FAT begins right after reserved sectors
}

int main () {
	std::cout << "Started Program.\n";
	
    FILE *disk = fopen("../floppy.img", "rb");


	std::cout << "Reading Boot Sector...\n";

	if(!readBootSector(disk)) {
		std::cout << "Error reading Boot Sector!\n";
		return -1;
	}


	std::cout << "Reading File Allocation Table...\n";

	if(!readFat(disk)) {
		std::cout << "Error reading FAT!\n";
		delete[] fat;
		return -1;
	}

	std::cout << "Program finished successfully\n";
    
	delete[] fat;
    return 0;
}