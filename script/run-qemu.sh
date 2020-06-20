#!/bin/bash

QEMU=qemu-system-riscv64

if [ -z $ARCH ]; then
	ARCH=riscv
fi
if [ -z $BBL ]; then
	BBL=riscv-pk
fi
if [ "x$BBL" = "xsdfirm" ]; then
	BBL_ELF=obj/sdfirm-${ARCH}/sdfirm
fi
if [ "x$BBL" = "xriscv-pk" ]; then
	BBL_ELF=obj/bbl/bbl
fi

which $QEMU
if [ $? -eq 0 ]
then
	$QEMU -nographic -machine virt -bios $BBL_ELF
else
	echo "No QEMU found"
fi
