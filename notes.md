# Notes on Assembly

## General Purposes Registers
- eax
- ebx
- ecx
- edx
- esi
- edi

## Specific Purposes Registers
- ebp (contains address of the bottom of the stack frame)
- esp (contains address of the top of the stack frame)
- eip (contains address of the instruction currently being executed)


## Memory Segmentation
These registers are used to specify currently active segments:
- CS: currently running code segment
- DS: data segment
- SS: stack segment
- ES,FS,GS: extra (data) segments

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

to run the OS: qemu-system-i386 -fda build/main_floppy.img

## Bootloader
- Loads basic components into memory
- Puts system in expected state
- Collects information about system

## Kernel

