# tiny-linux
Script and configuration for building tiny linux

(1) Prepare source codes and tools.

Checkout submodule.

	tiny-linux$ git submodule init
	tiny-linux$ git submodule update

Download tarballs for linux kernel and busybox. Then extract.

	tiny-linux$ tar xf archive/linux-5.6.14.tar
	tiny-linux$ tar jxf archive/busybox-1.31.1.tar.bz2 

Set PATH for cross-compile tool and QEMU. For example:

	tiny-linux$ export PATH=$PATH:/opt/riscv/bin/
	tiny-linux$ export PATH=$PATH:/opt/qemu/bin/

(2) Build all using script/build.sh

Check out the versions of linux kernel and busybox in build.sh. For example:

	BUSYBOX_VER=1.31.1 
	LINUX_VER=5.6.14

Run build.sh

	tiny-linux$ ./script/build.sh

(3) Run tiny linux in QEMU

	tiny-linux$ ./script/run-qemu.sh
