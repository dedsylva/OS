# Notes on Assembly
to run the OS: qemu-system-i386 -fda build/main_floppy.img

## How a Computer Starts UP
1. BIOS (Basic Input/Output System) is copied from a ROM chip into RAM
2. BIOS starts executing code
 - initializes hardware
 - runs some tests (POST= power-on self test)
3. BIOS searches for an operating system to start
4. BIOS loads and starts the operating system

## How the BIOS finds an OS
### Legacy Booting
- BIOS loads first sector of each bootable device into memory (at 0x7C00)
- BIOS checks for 0xAA55 signature
- If found, it starts executing code


## General Purposes Registers (divided in Low and High)
- eax/ax: 16 bits divided in two 8-bits registers ah (high) and al (low)
- ebx/bx: 16 bits divided in two 8-bits registers ah (high) and al (low)
- ecx/cx: 16 bits divided in two 8-bits registers ah (high) and al (low)
- edx/dx: 16 bits divided in two 8-bits registers ah (high) and al (low)

## Sement Registers
- cs (currently running code segment)
- ds (data segment)
- es (extra data segment)
- fs (extra data segment)
- gs (extra data segment)
- ss (stack segment)

## Index and Pointers Registers
- ebp (contains address of the bottom of the stack frame)
- esp (contains address of the top of the stack frame)
- eip (contains address of the instruction currently being executed)
- esi (source index)
- edi (destination index)

## Indicator Register
- eflags

## Memory Segmentation
real_address = segment * 16 + offset

## Referencing a memory locationn

### segment: [base + index * scale + displacement]
- segment: CS, DS, ES, FS, GS, SS 
 - if unspecified: SS when base register is BP
                   DS otherwise
- base: (16 bits) BP/BX
        (32/64 bits) any general purpose register
- index: (16 bits) SI/DI
         (32/64 bits) any general purpose register
- scale: (32/64 bits only) 1, 2, 4 or 8
- displacement: a (signed) constant value

## Interrupts
A signal which makes the processor stop what it's doing, in order to handle that signal.
Can be triggered by:
1. Exception (e.g. dividing by zero, segmentation fault, page fault);
2. Hardware (e.g. key pressed or release, disk controller finished an operation);
3. Software (through the INT instruction)

## Bootloader
- Loads basic components into memory
- Puts system in expected state
- Collects information about system

## Kernel


## Reading Data from Disks (CD, HD, etc)
- Dividing in Rings
 - Each ring is a Track/Cylinder
- Dividing in Pizza Slices
 - Each slice is a Sector
- Floppy Disks and HD can store data at both sides of the disk, so we call each side a Head.
- A disk can have more than one platter (a bunch of disks stack up to each other).
- To Read/Write something, we need to specify where the data is. We can do it using the CHS system, providing:
 - Cylinder Number (starts with 0)
 - Head Number (starts with 0)
 - Sector Number (starts with 1)

When working with disks, we don't really care where exactly the data is, we just need to know if it is in the beginning, middle, or end of the sdisk. So we can specify this using the Logic Block Address Scheme (LBA). In that way, instead of three numbers you only need one to get/write data on the disk.
However, the BIOS works only with the CHS, so we need to convert the addresses.


### Conversion Equations
LBA -> Logic Block Address
SPR -> sectors per track
* sector = (LBA % spr) + 1
* head = (LBA / spr) % heads
* cylinder = (LBA / spr) / heads 

## FAT (12) File System
Just like disks have sectors, FAT uses clusters. They are divided in:
* Reserved
* File Allocation Tables
* Root Directory
* Data
The cluster number gives the location in the data region and starts from 2. Converting to a sector number we have the equation:
-> lba = data_region_begin + (cluster-2) * sectors_per_cluster 


## Bootloader in C (goodbye assemebly)
Bootloader has three properties:
* Collects information about system 
* Puts system in state expected by kernel
* Loads and executes Kernel

## Compilers
We are going to tackle the first three, since the last one we already have it with our limited 512 bytes boot sector. 

So we are going to move from 16-bit real mode to 64-bit protected mode, by adding a <b>second stage to the bootloader</b>. To do that we'll move from assembly to c, but unfortunately we won't be able to run gcc, because we are in 16-bit real mode (although we will transition, some of the code will still be in 16-bit). So we'll use a compiler that was pretty popular and good in the 80s, early 90s: Open-Watcom.

### CDECL calling function convention
In order to guarantee compatibility across softwares, there are some conventions that you must follow, so that the compiler knows how to act when calling a function. For the 16-bit and 32-bit one common is the CDECL, which is the one we'll use. The rules are:

#### Arguments
* Passes through stack
* Pushed from right to left
* Calller removes parameters from stack

### Return
* Integers, memory addresses (pointers) should be returned at the EAX register
* Floating points should be returned at the ST0 register

### Registers
* EAX, ECX, EDX saved by caller
* All others are saved by callee (must be restored to original values before returning)

### Naming
* C functions must start with a _


### Printf
In order to implement a simple version of printf, the first thing we need to be concerned is with the number of parameters. The advantage of the stack growing downward is that we always know where the first argument is ([bp + 4]), so we simply count + 2 until the size has been reach. In order to know the size of the arguments, we need to parse them. Once this is sorted out, we can simply write a pointer that goes along each parameter, as shown below.

```c
void my_printf(const char* fmt, ...) {
	int* argp = (int*)&fmt; 							 // pointer pointing to format string
	argp += sizeof(fmt) / sizeof(int);		 // we need to divide because fmt is a vector
}
```

One thing to remember is that <b>the stack pointer is always aligned to the bit sized of the mode being used by the processor</b>. This means that in 16-bit real mode any argument smaller than 16-bits(char or unsigned char) will be promoted to 16-bit. The same is true for 32-bit and 64-bit mode.


#### State Machine Code Logic
The complete explanation can be found [here](https://www.youtube.com/watch?v=dG8PV6xqm4s&ab_channel=nanobyte&t=427)

![StateMachine](https://github.com/dedsylva/OS/blob/main/images/state_machine.png)


## Protected Mode - 1MB of Memory!
With the rise of Intel's 80286 AMDS's (and later Athlon 64) processor, we now have <b>privilege levels</b> (aka rings). Now we can decide who gets what access, giving us more safety. The rings are from 0 to 3, with 0 being <b>the kernel's level</b>, i.e., the most privileged one. The kernel decides if it can allows for more memory/hardware allocation. 

Switching from a privileged level to another is not done arbitrarily. For a program to call the kernel to do something, it has to perform a <b>system call</b>. This will make the transition to ring 0, and after the system call finishes, the cpu (or interrupts) makes the switch back to ring 3.

### Goodbye BIOS Interrupts
Due to the <b>No Free Lunch Theorem</b> (just kidding) we cannot use the BIOS interrupts calls anymore (something we were doing for reading the disk and printing text to the screen). Now we have to write our own drivers.

	

### Segmentation
Segmentation provides a mechanism for dividing the processor’s <b>linear address space</b> (addressable memory space) into smaller protected address spaces called <b>segments</b>. Segments can be used to hold the code, data, and stack for a program or to hold system data structures. If more than one program/task is running, each can be assigned its own set of segments. The processor enforces the boundaries between these segments and ensures that one program does not interfere with the other. All the segments in a system are contained in the processor’s linear address space. To locate a byte in a particular segment, a logical address (also called a far pointer) must be provided. A logical address consists of a segment selector (unique identifier) and an offset (that will be summed with the base address).

### Paging
The memory space that can be seen by a program/kernel can be completely remapped by the kernel. Using this feature, programs can be completely isolated from each other, without having the risk of sharing memory. In a last resort, the OS can swap memory in regions of disk that aren't frequently used in case of low physical memory.


![Segmentation_and_Paging](https://github.com/dedsylva/OS/blob/main/images/segmentation_and_paging.png)
Source: [Intel 64 and IA-32 architectures software developer’s manual](https://www.intel.com/content/www/us/en/developer/articles/technical/intel-sdm.html)

These two mechanisms (segmentation and paging) can be configured to suppoort single-program (or single-task) systems, or multiple-processor systems that used shared memory. 

## Documentations
* https://www.eecg.utoronto.ca/~amza/www.mindsec.com/files/x86regs.html
* https://wiki.osdev.org
