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


## Documentation
* https://www.eecg.utoronto.ca/~amza/www.mindsec.com/files/x86regs.html
