#!/bin/bash

ARCH=riscv
SPIKE=spike
SMP=4

if [ -z $BBL ]; then
	BBL=riscv-pk
fi
if [ "x$BBL" = "xsdfirm" ]; then
	BBL_ELF=obj/sdfirm-${ARCH}/sdfirm
fi
if [ "x$BBL" = "xriscv-pk" ]; then
	BBL_ELF=obj/bbl/bbl
fi

which $SPIKE
if [ $? -eq 0 ]
then
	$SPIKE -p$SMP $BBL_ELF
else
	echo "No Spike found"
fi
