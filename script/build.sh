#!/bin/bash

TOP=`pwd`
SCRIPT=`(cd \`dirname $0\`; cd ..; pwd)`
ARCH=riscv
#CROSS_COMPILE=riscv64-unknown-linux-gnu-
CROSS_COMPILE=riscv64-linux-gnu-

#LLVM_BUSYBOX=1
#LLVM_LINUX=1
#LLVM_OPENSBI=1

BUSYBOX_VER=1.31.1
BUSYBOX_CONFIG=config-busybox-$BUSYBOX_VER-$ARCH-initrd
BUSYBOX_CONFIG=config-busybox-$BUSYBOX_VER-$ARCH-min
BUSYBOX_CONFIG=config-busybox-$BUSYBOX_VER-$ARCH-bench
LINUX_CONFIG=config-linux-$LINUX_VER-$ARCH-initrd

LINUX_VER=5.13.0
LINUX_CONFIG=config-linux-$LINUX_VER-$ARCH-initramfs-dts

LINUX_VER=5.18.1
LINUX_CONFIG=config-linux-$LINUX_VER-$ARCH-initramfs-dts

INITRAMFS_FILELIST_TEMPLATE=$ARCH-initramfs-list
INITRAMFS_INIT=$ARCH-initramfs-init
#INITRAMFS_INIT=$ARCH-initramfs-init-bench

BBL_DTS=dts-riscv-spike

UBOOT_DIR=u-boot
#UBOOT_CONFIG=qemu-riscv64_smode_defconfig
UBOOT_CONFIG=qemu-riscv64-linux_defconfig
UBOOT_DTS=qemu-riscv64-virt
UIMAGE_ENTRY_ADDR=80400000

if [ -z $BUSYBOX_DIR ]; then
	BUSYBOX_DIR=busybox-$BUSYBOX_VER
fi
if [ -z $LINUX_DIR ]; then
	LINUX_DIR=linux-$LINUX_VER
fi

OPENSBI_DIR=opensbi
OPENSBI_ISA=rv64g
OPENSBI_DTS_LIST="qemu-riscv64-virt qemu-riscv64-spike"
OPENSBI_DTS_LIST="spike-spike-p4"
OPENSBI_FW_TEXT_START=0x80000000

# Customized start address
OPENSBI_FW_TEXT_START=0x4000400000
OPENSBI_FW_JUMP_ADDR=0x4000600000
OPENSBI_DTS_LIST="spike-riscv64-spike-p2m128"

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
	echo "(with built in DTB and Linux uImage as payload)"
	rm -rf $TOP/obj/uboot-$ARCH/
	mkdir $TOP/obj/uboot-$ARCH/
	cd $TOP/$UBOOT_DIR
	rm -rf payload/payload.bin
	mkimage -A $ARCH -O linux -T kernel -C none -a $UIMAGE_ENTRY_ADDR -e $UIMAGE_ENTRY_ADDR \
		-d $TOP/obj/linux-$ARCH/arch/$ARCH/boot/Image \
		payload/payload.bin
	make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE clean
	rm -rf arch/$ARCH/dts/$UBOOT_DTS.dtb
	dtc -I dts -O dtb arch/$ARCH/dts/$UBOOT_DTS.dts -o arch/$ARCH/dts/$UBOOT_DTS.dtb
	make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE $UBOOT_CONFIG
	make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE
	cp u-boot u-boot.bin $TOP/obj/uboot-$ARCH/
	cp arch/$ARCH/dts/$UBOOT_DTS.dts arch/$ARCH/dts/$UBOOT_DTS.dtb $TOP/obj/uboot-$ARCH/
	cd -
}

function build_opensbi_various()
{
	echo "== Build OpenSBI =="
	rm -rf $TOP/obj/opensbi-$ARCH/
	mkdir $TOP/obj/opensbi-$ARCH/
	cd $TOP/$OPENSBI_DIR

	for dts in $OPENSBI_DTS_LIST; do
		echo "Build OpenSBI with FDT $dts"
		gcc -E -nostdinc -undef -D__DTS__ -x assembler-with-cpp $SCRIPT/config/dts-$dts -o $TOP/obj/opensbi-$ARCH/$dts.dts
		dtc -I dts -O dtb $TOP/obj/opensbi-$ARCH/$dts.dts -o $TOP/obj/opensbi-$ARCH/$dts.dtb
		cp $SCRIPT/config/dts-$dts $TOP/obj/opensbi-$ARCH/$dts.dts
		rm -rf build
		make PLATFORM=generic CROSS_COMPILE=$CROSS_COMPILE FW_FDT_PATH=$TOP/obj/opensbi-$ARCH/$dts.dtb > /dev/null
		cp build/platform/generic/firmware/fw_payload.elf $TOP/obj/opensbi-$ARCH/${dts}_jump.elf
		cp build/platform/generic/firmware/fw_payload.bin $TOP/obj/opensbi-$ARCH/${dts}_jump.bin
		rm -rf build
		make PLATFORM=generic CROSS_COMPILE=$CROSS_COMPILE FW_TEXT_START=$OPENSBI_FW_TEXT_START FW_PAYLOAD_PATH=$TOP/obj/linux-$ARCH/arch/$ARCH/boot/Image FW_FDT_PATH=$TOP/obj/opensbi-$ARCH/$dts.dtb > /dev/null
		cp build/platform/generic/firmware/fw_payload.elf $TOP/obj/opensbi-$ARCH/${dts}_linux.elf
		cp build/platform/generic/firmware/fw_payload.bin $TOP/obj/opensbi-$ARCH/${dts}_linux.bin
		rm -rf build
		make PLATFORM=generic CROSS_COMPILE=$CROSS_COMPILE FW_PAYLOAD_PATH=$TOP/obj/uboot-$ARCH/u-boot.bin FW_FDT_PATH=$TOP/obj/opensbi-$ARCH/$dts.dtb > /dev/null
		cp build/platform/generic/firmware/fw_payload.elf $TOP/obj/opensbi-$ARCH/${dts}_uboot.elf
		cp build/platform/generic/firmware/fw_payload.bin $TOP/obj/opensbi-$ARCH/${dts}_uboot.bin
		ls -l $TOP/obj/opensbi-$ARCH/${dts}_*.*
	done

	echo "Build OpenSBI without FDT"
	rm -rf build
	make PLATFORM=generic CROSS_COMPILE=$CROSS_COMPILE > /dev/null
	cp build/platform/generic/firmware/fw_jump.elf $TOP/obj/opensbi-$ARCH/null_jump.elf
	cp build/platform/generic/firmware/fw_jump.bin $TOP/obj/opensbi-$ARCH/null_jump.bin
	rm -rf build
	make PLATFORM=generic CROSS_COMPILE=$CROSS_COMPILE FW_PAYLOAD_PATH=$TOP/obj/linux-$ARCH/arch/$ARCH/boot/Image > /dev/null
	cp build/platform/generic/firmware/fw_payload.elf $TOP/obj/opensbi-$ARCH/null_linux.elf
	cp build/platform/generic/firmware/fw_payload.bin $TOP/obj/opensbi-$ARCH/null_linux.bin
	rm -rf build
	make PLATFORM=generic CROSS_COMPILE=$CROSS_COMPILE FW_PAYLOAD_PATH=$TOP/obj/uboot-$ARCH/u-boot.bin > /dev/null
	cp build/platform/generic/firmware/fw_payload.elf $TOP/obj/opensbi-$ARCH/null_uboot.elf
	cp build/platform/generic/firmware/fw_payload.bin $TOP/obj/opensbi-$ARCH/null_uboot.bin
	ls -l $TOP/obj/opensbi-$ARCH/null_*.*

	cd -
}

function build_opensbi()
{
	echo "== Build OpenSBI =="
	rm -rf $TOP/obj/opensbi-$ARCH/
	mkdir $TOP/obj/opensbi-$ARCH/
	cd $TOP/$OPENSBI_DIR

	for dts in $OPENSBI_DTS_LIST; do
		echo "Build OpenSBI for FDT $dts"
		gcc -E -nostdinc -undef -D__DTS__ -x assembler-with-cpp $SCRIPT/config/dts-$dts -o $TOP/obj/opensbi-$ARCH/$dts.dts
		dtc -I dts -O dtb $TOP/obj/opensbi-$ARCH/$dts.dts -o $TOP/obj/opensbi-$ARCH/$dts.dtb
		cp $SCRIPT/config/dts-$dts $TOP/obj/opensbi-$ARCH/$dts.dts
		echo "- Build OpenSBI with $CROSS_COMPILE"
		rm -rf build
		make BUILD_INFO=y PLATFORM=generic PLATFORM_RISCV_ISA=$OPENSBI_ISA CROSS_COMPILE=$CROSS_COMPILE FW_TEXT_START=$OPENSBI_FW_TEXT_START FW_PAYLOAD_PATH=$TOP/obj/linux-$ARCH/arch/$ARCH/boot/Image FW_FDT_PATH=$TOP/obj/opensbi-$ARCH/$dts.dtb > /dev/null
		cp build/platform/generic/firmware/fw_payload.elf $TOP/obj/opensbi-$ARCH/opensbi_linux_$dts.elf
		cp build/platform/generic/firmware/fw_payload.bin $TOP/obj/opensbi-$ARCH/opensbi_linux_$dts.bin

		if [ -z $LLVM_OPENSBI ]
		then
			continue
		fi
		echo "- Build OpenSBI with LLVM"
		rm -rf build
		make BUILD_INFO=y PLATFORM=generic PLATFORM_RISCV_ISA=$OPENSBI_ISA LLVM=1 FW_TEXT_START=$OPENSBI_FW_TEXT_START FW_PAYLOAD_PATH=$TOP/obj/linux-$ARCH/arch/$ARCH/boot/Image FW_FDT_PATH=$TOP/obj/opensbi-$ARCH/$dts.dtb > /dev/null
		cp build/platform/generic/firmware/fw_payload.elf $TOP/obj/opensbi-$ARCH/opensbi_linux_$dts.llvm.elf
		cp build/platform/generic/firmware/fw_payload.bin $TOP/obj/opensbi-$ARCH/opensbi_linux_$dts.llvm.bin
		cp build/platform/generic/firmware/fw_payload.elf $TOP/obj/opensbi-$ARCH/opensbi_linux_$dts.llvm-fix-elftype.elf
		elfedit --output-type exec $TOP/obj/opensbi-$ARCH/opensbi_linux_$dts.llvm-fix-elftype.elf
	done
	ls -l $TOP/obj/opensbi-$ARCH/opensbi_linux*
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
	cp -rf $SCRIPT/bench/bench-auto.sh $TOP/$BENCH_BIN_DIR/bench-auto.sh
	cp -rf $SCRIPT/bench/bench-auto-mp.sh $TOP/$BENCH_BIN_DIR/bench-auto-mp.sh
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
	if [ -x ./usr/bin ]
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
	if [ -x ./usr/sbin ]
	then
		for f in `ls ./usr/sbin`
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
	elif [ "$1" == "opensbi" ]
	then
		build_opensbi
	fi
elif [ $# -eq 2 ]
then
	if [ "$1" == "bench" ]
	then
		if [ ! -x $2 ]
		then
			echo "Not found bench file $2"
			exit 2
		fi
		bench=$2
		echo "Build OpenSBI-Linux with bench $bench"
		rm -rf $TOP/$BENCH_BIN_DIR/*
		cp $bench $TOP/$BENCH_BIN_DIR/
		build_initramfs
		build_linux
		build_opensbi
		elf_file=$bench-opensbi_linux-$ARCH.elf
		mv $TOP/obj/opensbi-$ARCH/opensbi_linux.elf $elf_file
		ls -l $elf_file
	fi
else
		clean_all
		build_busybox
		build_initramfs
		build_linux
		build_opensbi
fi
