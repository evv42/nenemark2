# nenemark2 - NES/Famicom compatible 6502 computer

This 6502 hobby computer is designed with cheapness and modularity in mind.
A second goal is to be able to use a NES/Famicom/Famiclone as a base for this computer.  

There is no "standard" configuration, this computer can be equipped from 2KiB of RAM/ROM to 136 KiB RAM/ 32 KiB ROM.  

Common to all configuration is an I2C bitbanged bus that allows using a range of peripherals that is easier to interface and available, along with software-defined components.

## Contents

```
firmware : nenemark2 sources for building the ROM image. you'll need vasm6502_oldstyle
nenetalk : a serial interface using an arduino through nenemark2's I2C interface
nenescm.pdf : the schematics for nenemark2. I2C peripherals and the keyboard interface are not included
```

## NES/Famicom compatible ?

What it means:  
- RAM, ROM and Peripherals are mapped to the NES/Famicom cartridge address space (Work RAM excluded)
- Programmes don't use decimal mode
- NMI line isn't used

## Address space

```
(addresses in hex)
0000 - 1FFF : Work RAM. Can be either 2KiB mirrored or 8KiB
2000 - 4FFF : Unmapped for NES/Famicom compatibility
5000 - 5FFF : Peripherals :
  5000 - 51FF : IO Port (repeated 512 times) :
    Reading: Bit 0 is the data line of the AT Keyboard, Bit 1 is I2C SDA.
    Writing: Bit 0 is I2C SCL, Bit 1 is I2C SDA, Bit 2 is the piezo speaker, Bits 4-7 is the page of High RAM (0-F)
  5200 - 53FF : Reserved for future use, currently undefined
  5400 - 55FF : Reserved for future use, currently undefined
  5600 - 57FF : Reserved for future use, currently undefined
  5800 - 59FF : User peripheral 1 (512 bytes)
  5A00 - 5BFF : User peripheral 2 (512 bytes)
  5C00 - 5DFF : User peripheral 3 (512 bytes)
  5E00 - 5FFF : User peripheral 4 (512 bytes)
6000 - 7FFF : High RAM. 8 KiB pages, can be 0, 8, 32 or 128 KiB. Pages are controlled by the high nibble of the IO port.
8000 - FFFF : ROM (32 KiB)

```

## Legal annoyances (licensing, that is GPL2-only)

Copyright (C) 2024 evv42

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA. 
