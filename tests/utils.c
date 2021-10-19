// Checks if A20 gate is already enabled
bool TestA20(){
	uint32_t* lowMem = (uint32_t*)0x500; // 0x500 is the lowest address free to use
	*lowMem = 0xC0DE1234;

	uint32_t* highMem = (uint32_t*)0x100500; // in real mode corresponds to FFFFh:0510h
	if (*highMem == *lowMem)
		return false; // A20 is disabled

	return true;
}
