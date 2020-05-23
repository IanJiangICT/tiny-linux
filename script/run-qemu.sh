#!/bin/bash

QEMU=qemu-system-riscv64
which $QEMU
if [ $? -eq 0 ]
then
	$QEMU -nographic -machine virt -bios obj/bbl/bbl
else
	echo "No QEMU found"
fi
