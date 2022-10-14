#include <iostream>
#include <fstream>
#include <cstdint>
#include <cstring>

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

	// ===== Extended Boot Record (specific to FAT12 and FAT16):
	uint8_t driveNumber;
	uint8_t reserved;
	uint8_t signature;
	uint8_t volumeId[4]; // arbitrary 4 byte id
	uint8_t volumeLabel[11]; // arbitrary String padded to 11 bytes
	uint8_t systemId[8]; // FAT variant, padded to 8 bytes
};

struct __attribute__((packed)) DirectoryEntry {
	uint8_t name[11];
	uint8_t attributes;
	uint8_t reserved;

	uint8_t creationTimeTenths;
	uint16_t creationTime;
	uint16_t creationDate;
	uint16_t accessDate;

	uint16_t firstClusterHigh;

	uint16_t modifiedTime;
	uint16_t modifiedDate;

	uint16_t firstClusterLow;

	uint32_t size;
};


BootSector bootSector;
uint8_t* fat;
DirectoryEntry* rootDirectory = nullptr;
uint32_t rootDirectoryEndSector; // Last sector number that's part of root directory

bool readBootSector(FILE* disk) {
	fread(&bootSector, sizeof(BootSector), 1, disk);
	return true;
}

bool readSectors(FILE* disk, uint32_t lba, uint32_t count, void* dst) { // disk, LogicalBlockAddress, numBlocks, output
	bool ok = true;
	ok &= fseek(disk, lba * bootSector.bytesPerSector, SEEK_SET) == 0;
	ok &= fread(dst, bootSector.bytesPerSector, count, disk) == count;
	return ok;
}

bool readFat(FILE *disk) {
	fat = new uint8_t[bootSector.sectorsPerFat * bootSector.bytesPerSector];
	return readSectors(disk, bootSector.reservedSectors, bootSector.sectorsPerFat, fat); // FAT begins right after reserved sectors
}

bool readRootDirectory(FILE *disk) {
	const uint32_t lba =
			bootSector.reservedSectors
			+ bootSector.fatCount * bootSector.sectorsPerFat;
	const uint32_t size =
			bootSector.dirEntriesCount * sizeof(DirectoryEntry);
	const uint32_t numSectors =
			size / bootSector.bytesPerSector
			+ (size % bootSector.bytesPerSector != 0 ? 1 : 0);
	rootDirectoryEndSector = lba + numSectors;
	rootDirectory = new DirectoryEntry[bootSector.dirEntriesCount]; // (numSectors * bootSector.bytesPerSector) bytes
	return readSectors(disk, lba, numSectors, rootDirectory);
}

DirectoryEntry *findFile(const char *name) {
	for(size_t i = 0; i < bootSector.dirEntriesCount; i++)
		if(memcmp(rootDirectory[i].name, "KERNEL  BIN", 11) == 0)
			return rootDirectory + i;
	return nullptr;
}


bool readFile(const DirectoryEntry* file, FILE *disk, uint8_t* dst) {
	uint32_t currentCluster = file->firstClusterLow; // current cluster

	bool ok = true;

	do {
		const uint32_t lba = rootDirectoryEndSector + (currentCluster - 2) * bootSector.sectorsPerCluster;
		// const uint32_t fatVal = fatEntry(currentCluster);
		// printf("FAT Entry: %04x\n", fatVal);

		ok &= readSectors(disk, lba, bootSector.sectorsPerCluster, dst);

		dst += bootSector.sectorsPerCluster * bootSector.bytesPerSector;
		
		const uint32_t fatIndex = currentCluster * 3 / 2;
		if(currentCluster % 2 == 0)
			currentCluster = (*(uint16_t*)(fat + fatIndex)) & 0x0FFF; // remove highest nibble
		else
			currentCluster = (*(uint16_t*)(fat + fatIndex)) >> 4; // remove lowest nibble
	} while(ok && currentCluster < 0xFF8);

	return ok;
}

int main () {
	std::cout << "Started Program.\n";
	
    FILE *disk = fopen("../floppy.img", "rb");

	if(!disk) {
		std::cout << "Error opening Disk file\n";
		return -1;
	}


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

	std::cout << "Extracting root Directory...\n";

	if(!readRootDirectory(disk)) {
		std::cout << "Error reading Root Directory!\n";
		delete[] rootDirectory;
		delete[] fat;
		return -1;
	}

	// char *rootC = (char*)rootDirectory;
	// for(size_t y = 0; y < 16; y++) {
	// 	for(size_t x = 0; x < 32; x++) {
	// 		const char c = rootC[y * 32 + x];
	// 		if(c > 'A' && c < 'z')
	// 			putchar(c);
	// 		else
	// 			putchar(' ');
	// 	}
	// 	putchar('\n');
	// }
	// return 0;

	std::cout << "Number of root Directory entries: "
		<< bootSector.dirEntriesCount << "\n";

	std::cout << "Searching KERNEL.BIN ...\n";

	DirectoryEntry *kernel = findFile("KERNEL  BIN");
	if(kernel == nullptr) {
		std::cout << "Error finding Kernel File!\n";
		delete[] rootDirectory;
		delete[] fat;
		return -1;
	}


	std::cout << "Reading KERNEL.BIN ...\n";
	std::cout << "Size: " << kernel->size << " Bytes\n";

	uint8_t *kernelData = new uint8_t[kernel->size + bootSector.bytesPerSector + 1]{};
	if(!readFile(kernel, disk, kernelData)) {
		std::cout << "Error reading Kernel File!\n";
		delete[] kernelData;
		delete[] rootDirectory;
		delete[] fat;
		return -1;
	}

	std::cout << "Kernel.bin contains: " << (char*)kernelData << "\n";


	delete[] kernelData;
	delete[] rootDirectory;
	delete[] fat;

	std::cout << "Program finished successfully\n";

    return 0;
}