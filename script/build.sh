#!/bin/bash

TOP=`pwd`
ARCH=riscv
CROSS_COMPILE=riscv64-unknown-linux-gnu-

BUSYBOX_VER=1.31.1
LINUX_VER=5.6.14

BUSYBOX_CONFIG=config-busybox-$BUSYBOX_VER-$ARCH-initrd
BUSYBOX_CONFIG=config-busybox-$BUSYBOX_VER-$ARCH-min
LINUX_CONFIG=config-linux-$LINUX_VER-$ARCH-initrd
LINUX_CONFIG=config-linux-$LINUX_VER-$ARCH-initramfs-d05261647
LINUX_CONFIG=config-linux-$LINUX_VER-$ARCH-initramfs-d06041530
LINUX_CONFIG=config-linux-$LINUX_VER-$ARCH-initramfs-d06041659
INITRAMFS_FILELIST_TEMPLATE=$ARCH-initramfs-list

if [ -z $BUSYBOX_DIR ]; then
	BUSYBOX_DIR=busybox-$BUSYBOX_VER
fi
if [ -z $LINUX_DIR ]; then
	LINUX_DIR=linux-$LINUX_VER
fi
INITRAMFS_DIR=obj/initramfs/$ARCH
INITRAMFS_FILELIST=obj/initramfs/list-$ARCH
BBL_DIR=obj/bbl

BENCH_BIN_DIR=obj/bench-$ARCH

ARCHIVES_DIR=$TOP/archive


function clean_all()
{
	echo "== Clean all =="
	rm -rf $TOP/obj/busybox-$ARCH
	rm -rf $TOP/$INITRAMFS_DIR
	rm -rf $TOP/obj/linux-$ARCH
	rm -rf $TOP/$BBL_DIR
}

function build_busybox()
{
	echo "== Build Busybox =="
	rm -rf $TOP/obj/busybox-$ARCH
	cd $TOP/$BUSYBOX_DIR
	mkdir -pv $TOP/obj/busybox-$ARCH
	cp $TOP/config/$BUSYBOX_CONFIG ./.config
	make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE O=$TOP/obj/busybox-$ARCH oldconfig
	make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE mrproper
	cd $TOP/obj/busybox-$ARCH
	make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE -j6
	make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE install
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
	cp -rf $TOP/config/$INITRAMFS_FILELIST_TEMPLATE $TOP/$INITRAMFS_FILELIST
	cd $TOP/$INITRAMFS_DIR
	cp -av $TOP/obj/busybox-$ARCH/_install/* .
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
	for f in `ls ./sbin`
	do
		grep $f $TOP/$INITRAMFS_FILELIST >> /dev/null
		if [ $? == 1 ]
		then
			echo "slink /sbin/$f ../bin/busybox 777 0 0" >> $TOP/$INITRAMFS_FILELIST
		fi
	done
	for f in `ls ./usr/bin`
	do
		grep $f $TOP/$INITRAMFS_FILELIST >> /dev/null
		if [ $? == 1 ]
		then
			echo "slink /usr/bin/$f ../../bin/busybox 777 0 0" >> $TOP/$INITRAMFS_FILELIST
		fi
	done

	mkdir ./bench
	cp -rf $TOP/$BENCH_BIN_DIR/* ./bench
	for f in `ls ./bench`
	do
		echo "file /bench/$f ../../$INITRAMFS_DIR/bench/$f 755 0 0" >> $TOP/$INITRAMFS_FILELIST
	done

	echo "Use INITRAMFS_SOURCE file list: $INITRAMFS_FILELIST"
	grep INITRAMFS_SOURCE $TOP/config/$LINUX_CONFIG
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
	cp $TOP/config/$LINUX_CONFIG arch/$ARCH/configs/my_defconfig
	make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE O=$TOP/obj/linux-$ARCH my_defconfig
	make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE O=$TOP/obj/linux-$ARCH -j6
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

function build_bbl()
{
	echo "== Build bbl =="
	rm -rf $TOP/$BBL_DIR
	mkdir -pv $TOP/$BBL_DIR
	cd $TOP/$BBL_DIR
	$TOP/riscv-pk/configure  --enable-logo --host=riscv64-unknown-linux-gnu --with-payload=$TOP/obj/linux-$ARCH/vmlinux
	make
	cd -
}

cd $TOP

echo "== Prepare =="
if [ ! -f $TOP/config/$LINUX_CONFIG ]
then
	echo "Linux config not found $LINUX_CONFIG"
	exit 1
fi

if [ ! -f $TOP/config/$BUSYBOX_CONFIG ]
then
	echo "Busybox config not found $BUSYBOX_CONFIG"
	exit 1
fi

if [ ! -f $TOP/riscv-pk/README.md ]
then
	echo "Submodule riscv-pk not checkeck out"
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
	elif [ "$1" == "bbl" ]
	then
		build_bbl
	fi
else
		clean_all
		build_busybox
		build_initramfs
		build_linux
		build_bbl
fi
