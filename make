#!/bin/bash
fasm loader.fasm
fasm init.fasm
cat loader.bin init.bin > os.bin
