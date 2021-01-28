#!/bin/bash

# - Local tftp server is required.
# - IP addresses of server and client should be configured in u-boot. For example:
# #define CONFIG_BOOTCOMMAND  \
#     "tftp 0x60500000 vexpress-v2p-ca9.dtb; tftp 0x60500000 vexpress-v2p-ca9.dtb; tftp 0x60003000 uImage; \
#     setenv bootargs 'console=ttyAMA0';  \
#     bootm 0x60003000 - 0x60500000;"
#
# #define CONFIG_IPADDR   192.168.2.110
# #define CONFIG_SERVERIP 192.168.2.25
# #define CONFIGN_NETMASK 255.255.255.1

FTP_DIR=/srv/tftp

# For machine vexpress a9
cp -f obj/linux-arm/arch/arm/boot/uImage $FTP_DIR/
cp -f obj/linux-arm/arch/arm/boot/dts/vexpress-v2p-ca9.dtb $FTP_DIR/

sudo qemu-system-arm -nographic \
	-machine vexpress-a9 \
	-cpu cortex-a9 \
	-smp 4 \
	-m 512M \
	-kernel obj/uboot-arm/u-boot \
	-net nic -net tap,ifname=tap0
