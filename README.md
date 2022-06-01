# Tiny Linux

Script and configuration for building tiny Linux

1. **Prepare source codes and tools.**

Download tarballs for Linux kernel and busybox. Then extract.

```bash
tiny-linux$ tar xf archive/linux-5.6.14.tar
tiny-linux$ tar jxf archive/busybox-1.31.1.tar.bz2 
```
Apply pathes if any. For exmaple:

```bash
tiny-linux$ cd busybox-1.31.1
busybox-1.31.1$ patch -p 1 -i ../patch/busybox-1.31.1-patch-stime
```

Set PATH for cross-compile tool and QEMU. For example:

```bash
tiny-linux$ export PATH=$PATH:/opt/riscv/bin/
tiny-linux$ export PATH=$PATH:/opt/qemu/bin/
```

2. **Build all using script/build.sh**

Check out the versions of linux kernel and busybox in build.sh. For example:

```bash
BUSYBOX_VER=1.31.1 
LINUX_VER=5.6.14
``` 

Run build.sh

```bash
tiny-linux$ ./script/build.sh
```

3. **Run tiny Linux in QEMU**

```bash
tiny-linux$ ./script/run-qemu.sh
```

4. **Upgrade Linux kernel**

From linux 5.13.0 to 5.18.1 for example:
```bash
tiny-linux$ cd linux-5.18.1
linux-5.18.1$ cp ../config/config-linux-5.13.0-riscv-initramfs-dts ./.config
linux-5.18.1$ make ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- oldconfig # Check out each new configuration
linux-5.18.1$ cp .config ../config/config-linux-5.18.1-riscv-initramfs-d06011648
linux-5.18.1$ cd -
tiny-linux$ vim ./script/build.sh # Define new $LINUX_VER and $LINUX_CONFIG
tiny-linux$ ./script/build.sh linux
```
