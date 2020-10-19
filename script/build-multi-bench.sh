#!/bin/bash

TOP=`pwd`
ARCH=riscv
BENCH_BIN_DIR=obj/bench-$ARCH

bench_src=./bench
if [ $# -eq 1 ];
then
	bench_src=$1
fi
output=./bench-$ARCH

echo "Build for each bench under $bench_src"

mkdir $output

cd $bench_src
bench_list=`ls *.tar`
cd - >> /dev/null

for bench in $bench_list; do
	echo "Build for $bench"
	./script/build.sh bench $bench_src/$bench
	mv $TOP/obj/bbl/bbl-*-$ARCH.elf ./$output/
	cp $TOP/obj/linux-$ARCH/arch/$ARCH/boot/Image ./$output/Image-$ARCH-$bench
done
