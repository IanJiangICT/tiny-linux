#!/bin/bash

TOP=`pwd`
SCRIPT=`(cd \`dirname $0\`; cd ..; pwd)`
ARCH=riscv
CROSS_COMPILE=riscv64-unknown-linux-gnu-

BUSYBOX_VER=1.31.1
LINUX_VER=5.6.14
LINUX_VER=5.8.10

BUSYBOX_CONFIG=config-busybox-$BUSYBOX_VER-$ARCH-initrd
BUSYBOX_CONFIG=config-busybox-$BUSYBOX_VER-$ARCH-min
BUSYBOX_CONFIG=config-busybox-$BUSYBOX_VER-$ARCH-bench
LINUX_CONFIG=config-linux-$LINUX_VER-$ARCH-initrd
LINUX_CONFIG=config-linux-$LINUX_VER-$ARCH-initramfs-d05261647
LINUX_CONFIG=config-linux-$LINUX_VER-$ARCH-initramfs-d06041530
LINUX_CONFIG=config-linux-$LINUX_VER-$ARCH-initramfs-d06041659
LINUX_CONFIG=config-linux-$LINUX_VER-$ARCH-initramfs-d09210936
#LINUX_CONFIG=config-linux-$LINUX_VER-$ARCH-initramfs-a5dc8300d
INITRAMFS_FILELIST_TEMPLATE=$ARCH-initramfs-list
INITRAMFS_INIT=$ARCH-initramfs-init
#INITRAMFS_INIT=$ARCH-initramfs-init-bench

BBL_DTS=dts-riscv-spike

if [ -z $BUSYBOX_DIR ]; then
	BUSYBOX_DIR=busybox-$BUSYBOX_VER
fi
if [ -z $LINUX_DIR ]; then
	LINUX_DIR=linux-$LINUX_VER
fi
if [ -z $BBL ]; then
	BBL=riscv-pk
fi
if [ "x$BBL" = "xsdfirm" ]; then
	if [ -z $SDFIRM_DIR ]; then
		SDFIRM_DIR=sdfirm
	fi
	if [ -z $MACH ]; then
		MACH=spike64
	fi
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
	cp $SCRIPT/config/$BUSYBOX_CONFIG ./.config
	make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE O=$TOP/obj/busybox-$ARCH/ oldconfig
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
	cp -rf $SCRIPT/config/$INITRAMFS_FILELIST_TEMPLATE $TOP/$INITRAMFS_FILELIST
	cp -rf $SCRIPT/config/$INITRAMFS_INIT $TOP/obj/riscv-initramfs-init
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

function build_sdfirm()
{
	echo "== Build sdfirm =="
	rm -rf $TOP/obj/sdfirm-$ARCH
	mkdir -p $TOP/obj/sdfirm-$ARCH
	cd $TOP/$SDFIRM_DIR
	if [ -x $TOP/obj/sdfirm-$ARCH ]; then
		make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE O=$TOP/obj/sdfirm-$ARCH/ distclean
	fi
	make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE distclean
	make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE O=$TOP/obj/sdfirm-$ARCH/ ${MACH}_bbl_defconfig
	ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPLE $SDFIRM_DIR/scripts/config \
		--file $TOP/obj/sdfirm-$ARCH/.config \
		--set-str CONFIG_SBI_PAYLOAD_PATH ../linux-$ARCH/arch/$ARCH/boot/Image
	make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE O=$TOP/obj/sdfirm-$ARCH/ -j6
	if [ ! -f $TOP/obj/sdfirm-$ARCH/sdfirm ]
	then
		echo "Error: Failed to build sdfirm"
		exit 1
	fi
	${CROSS_COMPILE}objcopy --only-keep-debug $TOP/obj/sdfirm-$ARCH/sdfirm $TOP/obj/sdfirm-$ARCH/sdfirm.sym
	cd -
}

function build_riscv-pk()
{
	echo "== Build riscv-pk =="
	rm -rf $TOP/$BBL_DIR
	mkdir -pv $TOP/$BBL_DIR
	cd $TOP/$BBL_DIR
	dtc -I dts $SCRIPT/config/$BBL_DTS -o $TOP/$BBL_DIR/$BBL_DTS.bin
	$SCRIPT/riscv-pk/configure  --enable-logo --host=riscv64-unknown-linux-gnu \
		--with-fdt=$TOP/$BBL_DIR/$BBL_DTS.bin \
		--with-payload=$TOP/obj/linux-$ARCH/vmlinux
	make
	cd -
}

function build_bbl()
{
	if [ "x$BBL" = "xriscv-pk" ]; then
		build_riscv-pk
	fi
	if [ "x$BBL" = "xsdfirm" ]; then
		build_sdfirm
	fi
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

if [ ! -f $SCRIPT/riscv-pk/README.md ]
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
elif [ $# -eq 2 ]
then
	if [ "$1" == "bench" ]
	then
		bench=$2
		rm -rf $TOP/$BENCH_BIN_DIR/*
		cp $bench $TOP/$BENCH_BIN_DIR/
		build_initramfs
		build_linux
		build_bbl
		bench_name=`ls $TOP/$BENCH_BIN_DIR/ | sed -E 's/.tar//'`
		bbl_file=$TOP/$BBL_DIR/bbl-$bench_name-$ARCH.elf
		echo "Result BBL with $bench"
		mv $TOP/$BBL_DIR/bbl $bbl_file
		ls -l $bbl_file
	fi
else
		clean_all
		build_busybox
		build_initramfs
		build_linux
		build_bbl
fi
