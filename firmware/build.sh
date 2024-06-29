#!/bin/sh
set -e
set -x
vasm6502_oldstyle -Fbin -dotdir rom.asm
mv a.out rom.bin && echo "build successful"
