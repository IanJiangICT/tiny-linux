#!/bin/bash

qemu-system-arm -nographic -machine vexpress-a9 -m 512M \
	-kernel obj/linux-arm/arch/arm/boot/zImage \ 
	-dtb obj/linux-arm/arch/arm/boot/dts/vexpress-v2p-ca9.dtb \
	-append "console=ttyAMA0"


