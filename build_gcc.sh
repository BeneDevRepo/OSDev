#!/bin/bash

# first install: build-essential texinfo binutils-dev libgmp3-dev libmpc-dev libmpfr-dev


mkdir -p toolchain/gcc-build

echo "==========================   Downloading gcc   =========================="
(cd toolchain \
	&& wget https://ftp.gnu.org/gnu/gcc/gcc-12.2.0/gcc-12.2.0.tar.gz \
	&& tar -xf gcc-12.2.0.tar.gz) &
wait


echo "==========================   Configuring gcc   =========================="
(cd toolchain/gcc-build \
	&& ../gcc-12.2.0/configure \
			--prefix=$(realpath ../) \
			--target="i686-elf" \
			--disable-nls \
			--enable-languages=c,c++ \
			--without-headers) &
wait


echo "==========================   Making gcc   =========================="
make -j8 -C toolchain/gcc-build all-gcc all-target-libgcc


echo "==========================   Installing gcc   =========================="
make -j8 -C toolchain/gcc-build install-gcc install-target-libgcc

# export PATH="$(realpath toolchain/bin):$PATH"