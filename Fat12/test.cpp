#include <iostream>
#include <fstream>
#include <cstdint>
#include <string_view>

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
	rootDirectory = new DirectoryEntry[bootSector.dirEntriesCount];
	bool ok = true;
	ok &= readSectors(
		disk,
		bootSector.reservedSectors + bootSector.fatCount * bootSector.sectorsPerFat,
		bootSector.dirEntriesCount * 32 / bootSector.bytesPerSector,
		rootDirectory);
	return ok;
}

uint16_t fatEntry(uint16_t index) {
	const auto nibble = [](const uint8_t* buffer, const uint16_t index) {
		if(index % 2 != 0)
			return buffer[index / 2] >> 4;
		return buffer[index / 2] & 0xF;
	};

	return nibble(fat, index * 3 + 0) << 8
	     | nibble(fat, index * 3 + 1) << 4
	     | nibble(fat, index * 3 + 2) << 0;
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

	if(!readRootDirectory(disk)) {
		std::cout << "Error reading Root Directory!\n";
		delete[] rootDirectory;
		return -1;
	}

	std::cout << "Number of root Directory entries: "
		<< bootSector.dirEntriesCount << "\n";

	for(size_t i = 0; i < bootSector.dirEntriesCount; i++) {
		const DirectoryEntry& dir = rootDirectory[i];

		const std::string_view name((char*)dir.name, 11);

		// std::cout << "Directory: " << name << "\n";

		const uint16_t clusterStart =
			bootSector.reservedSectors // skip reserved sectors (incuding Boot sector)
			+ bootSector.fatCount * bootSector.sectorsPerFat // skip File Allocation Table
			+ (bootSector.dirEntriesCount * 32 / bootSector.bytesPerSector); // skip root directory
		
		const uint16_t cluster = dir.firstClusterLow;

		const uint16_t fatVal = fatEntry(cluster);



		if(name == std::string_view("KERNEL  BIN")) {
			std::cout << "Kernel found: " << name << "\n";
			printf("Size: %dB\n", dir.size);
			printf("First Cluster: %d\n", clusterStart + cluster - 2);
			printf("FAT Entry: %04x\n", fatVal);

			uint8_t sector[512 + 1]{};
			readSectors(disk, clusterStart + cluster - 2, 1, sector);
			std::cout << "File Content: <" << sector << ">\n";
		}
		
	}

	std::cout << "Program finished successfully\n";

	delete[] rootDirectory;
	delete[] fat;
    return 0;
}