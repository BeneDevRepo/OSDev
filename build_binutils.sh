#!/bin/bash

# install build-essential, texinfo and binutils-dev first

mkdir -p toolchain/binutils-build


echo "==========================   Downloading Binutils   =========================="
(cd toolchain \
	&& wget https://ftp.gnu.org/gnu/binutils/binutils-2.38.tar.gz \
	&& tar -xf binutils-2.38.tar.gz) &
wait


echo "==========================   Configuring Binutils   =========================="
(cd toolchain/binutils-build \
	&& ../binutils-2.38/configure \
			--prefix=$(realpath ../) \
			--target="i686-elf" \
			--with-sysroot \
			--disable-nls \
			--disable-werror) &
wait


echo "==========================   Making Binutils   =========================="
make -j8 -C toolchain/binutils-build


echo "==========================   Installing Binutils   =========================="
make -j8 -C toolchain/binutils-build install

# export PATH="$(realpath toolchain/bin):$PATH"