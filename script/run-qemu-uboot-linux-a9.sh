FTP_DIR=/pub/tftpboot

cp -f ./uImage $FTP_DIR/
cp -f ./vexpress-v2p-ca9.dtb $FTP_DIR/

sudo qemu-system-arm -nographic \
	-machine vexpress-a9 \
	-cpu cortex-a9 \
	-smp 4 \
	-m 512M \
	-kernel u-boot \
	-net nic -net tap,ifname=tap0
