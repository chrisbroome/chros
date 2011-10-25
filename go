#!/bin/bash
qemu -fda ./myos.bin -boot a &
# gnome-terminal --geometry=120x50 --command="gdb" &
# gdb --eval-command="target remote localhost:1234" --eval-command="layout asm"

# Might switch to using bochs here once I read the documentation
