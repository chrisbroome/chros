#!/bin/bash
fasm loader.asm
fasm init.asm
cat loader.bin init.bin > os.bin
