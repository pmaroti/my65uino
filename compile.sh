#!/bin/sh
naken_asm -o 65uino.bin -type bin -l 65uino.asm
hexdump -v -e '16/1 "%02X " "\n"' 65uino.bin > 65uino.hex
echo "Assembled!"