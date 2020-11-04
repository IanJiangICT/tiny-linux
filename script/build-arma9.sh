#!/bin/bash

TOP=`pwd`
SCRIPT=`(cd \`dirname $0\`; cd ..; pwd)`
ARCH=arm
CROSS_COMPILE=arm-linux-gnueabi-

BUSYBOX_VER=1.31.1
LINUX_VER=5.8.10

UIMAGE_LOADADDR=0x60003000

BUSYBOX_CONFIG=config-busybox-$BUSYBOX_VER-$ARCH-test
# Linux kernel configs based on vexpress_defconfig
LINUX_CONFIG=config-linux-$LINUX_VER-$ARCH-initramfs-d10221549
LINUX_CONFIG=config-linux-$LINUX_VER-$ARCH-initramfs-d10260909
LINUX_CONFIG=config-linux-$LINUX_VER-$ARCH-initramfs-d10271344
INITRAMFS_FILELIST_TEMPLATE=$ARCH-initramfs-list
INITRAMFS_INIT=$ARCH-initramfs-init

UBOOT_CONFIG=qemu_arm_defconfig
UBOOT_CONFIG=highbank_defconfig

if [ -z $BUSYBOX_DIR ]; then
	BUSYBOX_DIR=busybox-$BUSYBOX_VER
fi
if [ -z $LINUX_DIR ]; then
	LINUX_DIR=linux-$LINUX_VER
fi

UBOOT_DIR=u-boot

INITRAMFS_DIR=obj/initramfs/$ARCH
INITRAMFS_FILELIST=obj/initramfs/list-$ARCH

BENCH_BIN_DIR=obj/bench-$ARCH

ARCHIVES_DIR=$TOP/archive


function clean_all()
{
	echo "== Clean all =="
	rm -rf $TOP/obj/busybox-$ARCH
	rm -rf $TOP/$INITRAMFS_DIR
	rm -rf $TOP/obj/linux-$ARCH
}

function build_busybox()
{
	echo "== Build Busybox =="
	rm -rf $TOP/obj/busybox-$ARCH
	cd $TOP/$BUSYBOX_DIR
	mkdir -pv $TOP/obj/busybox-$ARCH
	cp $SCRIPT/config/$BUSYBOX_CONFIG ./.config
	make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE O=$TOP/obj/busybox-$ARCH/ oldconfig
	make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE mrproper
	cd $TOP/obj/busybox-$ARCH
	make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE -j6
	make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE install
	cd -
}

function build_uboot()
{
	echo "== Build U-Boot =="
	cd $TOP/$UBOOT_DIR
	make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE clean
	make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE $UBOOT_CONFIG
	make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE
	cd -
}

function build_initramfs_old()
{
	echo "== Build initramfs =="
	rm -rf $TOP/$INITRAMFS_DIR
	mkdir -pv $TOP/$INITRAMFS_DIR
	cd $TOP/$INITRAMFS_DIR
	mkdir -pv {bin,sbin,dev,etc,proc,sys,usr/{bin,sbin}}
	cp -av $TOP/obj/busybox-$ARCH/_install/* .
	sudo mknod dev/ttyS0 c 5 1
	> ./init
	echo "#!/bin/busybox sh" >> ./init
	echo "" >> ./init
	#echo "/bin/busybox --install -s" >> ./init
	echo "mount -t proc none /proc" >> ./init
	echo "mount -t sysfs none /sys" >> ./init
	#echo "mount -t devtmpfs devtmpfs /dev" >> ./init
	echo "echo -e \"\nBoot took \$(cut -d' ' -f1 /proc/uptime) seconds\\n\" >> /dev/ttyS0" >> ./init
	echo "exec setsid sh -c 'exec sh </dev/ttyS0 >/dev/ttyS0 2>&1'" >> ./init
	chmod +x ./init
	find . | cpio -H newc -o > $TOP/obj/initramfs-$ARCH.cpio
	cd -
	cd $TOP/obj
	cat initramfs-$ARCH.cpio | gzip > initramfs-$ARCH.gz
	cd -
}

function build_initramfs()
{
	echo "== Build initramfs =="
	rm -rf $TOP/$INITRAMFS_DIR
	mkdir -pv $TOP/$INITRAMFS_DIR
	cp -rf $SCRIPT/config/$INITRAMFS_FILELIST_TEMPLATE $TOP/$INITRAMFS_FILELIST
	cp -rf $SCRIPT/config/$INITRAMFS_INIT $TOP/obj/$ARCH-initramfs-init
	cp -rf $SCRIPT/bench/bench-auto.sh $TOP/obj/bench-auto.sh
	cd $TOP/$INITRAMFS_DIR
	cp -av $TOP/obj/busybox-$ARCH/_install/* .
	if [ -x ./bin ]
	then
		for f in `ls ./bin`
		do
			if [ "$f" == "busybox" ]
			then
				continue
			fi
			grep $f $TOP/$INITRAMFS_FILELIST >> /dev/null
			if [ $? == 1 ]
			then
				echo "slink /bin/$f busybox 777 0 0" >> $TOP/$INITRAMFS_FILELIST
			fi
		done
	fi
	if [ -x ./sbin ]
	then
		for f in `ls ./sbin`
		do
			grep $f $TOP/$INITRAMFS_FILELIST >> /dev/null
			if [ $? == 1 ]
			then
				echo "slink /sbin/$f ../bin/busybox 777 0 0" >> $TOP/$INITRAMFS_FILELIST
			fi
		done
	fi
	if [ -x ./usr/sbin ]
	then
		for f in `ls ./usr/bin`
		do
			grep $f $TOP/$INITRAMFS_FILELIST >> /dev/null
			if [ $? == 1 ]
			then
				echo "slink /usr/bin/$f ../../bin/busybox 777 0 0" >> $TOP/$INITRAMFS_FILELIST
			fi
		done
	fi

	mkdir ./bench
	if [ -x $TOP/$BENCH_BIN_DIR ]
	then
		cp -rf $TOP/$BENCH_BIN_DIR/* ./bench
		for f in `ls ./bench`
		do
			echo "file /bench/$f ../../$INITRAMFS_DIR/bench/$f 755 0 0" >> $TOP/$INITRAMFS_FILELIST
		done
	fi

	echo "Use INITRAMFS_SOURCE file list: $INITRAMFS_FILELIST"
	grep INITRAMFS_SOURCE $SCRIPT/config/$LINUX_CONFIG
	echo "So initramfs is built not here now but together with kernel later"
	cat $TOP/$INITRAMFS_FILELIST
	cd -
}

function build_linux_5_6()
{
	echo "== Build Linux =="
	rm -rf $TOP/obj/linux-$ARCH
	#mkdir -p $TOP/obj/linux-$ARCH
	cd $TOP/$LINUX_DIR
	make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE distclean
	cp $SCRIPT/config/$LINUX_CONFIG arch/$ARCH/configs/my_defconfig
	make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE O=$TOP/obj/linux-$ARCH/ my_defconfig
	make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE O=$TOP/obj/linux-$ARCH/ -j6
	make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE O=$TOP/obj/linux-$ARCH/ LOADADDR=$UIMAGE_LOADADDR uImage
	if [ ! -f $TOP/obj/linux-$ARCH/vmlinux ]
	then
		echo "Error: Failed to build Linux"
		exit 1
	fi
	${CROSS_COMPILE}objcopy --only-keep-debug $TOP/obj/linux-$ARCH/vmlinux $TOP/obj/linux-$ARCH/kernel.sym
	cd -
}

function build_linux()
{
	build_linux_5_6
}



cd $TOP

echo "== Prepare =="
if [ ! -f $SCRIPT/config/$LINUX_CONFIG ]
then
	echo "Linux config not found $LINUX_CONFIG"
	exit 1
fi

if [ ! -f $SCRIPT/config/$BUSYBOX_CONFIG ]
then
	echo "Busybox config not found $BUSYBOX_CONFIG"
	exit 1
fi

if [ ! -d $LINUX_DIR ]
then
	echo "Linux source $LINUX_DIR not found"
	exit 1
fi

if [ ! -d $BUSYBOX_DIR ]
then
	echo "Busybox source $BUSYBOX_DIR not found"
	exit 1
fi

if [ $# -eq 1 ]
then
	if [ "$1" == "clean" ]
	then
		clean_all
	elif [ "$1" == "busybox" ]
	then
		build_busybox
	elif [ "$1" == "initramfs" ]
	then
		build_initramfs
	elif [ "$1" == "linux" ]
	then
		build_linux
	elif [ "$1" == "uboot" ]
	then
		build_uboot
	fi
else
		clean_all
		build_busybox
		build_initramfs
		build_linux
		build_uboot
fi
