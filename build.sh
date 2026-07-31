#!/bin/sh
set -e

mkdir -p output

for target in \
    "x86_64 gcc" \
    "i386 i686-linux-gnu-gcc" \
    "arm64 aarch64-linux-gnu-gcc" \
    "armhf arm-linux-gnueabihf-gcc" \
    "armel arm-linux-gnueabi-gcc" \
    "riscv64 riscv64-linux-gnu-gcc" \
    "mips mips-linux-gnu-gcc" \
    "mipsel mipsel-linux-gnu-gcc" \
    "ppc64 powerpc64-linux-gnu-gcc" \
    "ppc64le powerpc64le-linux-gnu-gcc" \
    "s390x s390x-linux-gnu-gcc"
do
    set -- $target

    ARCH=$1
    CC=$2

    cmake -S . -B build-$ARCH \
        -DCMAKE_C_COMPILER=$CC \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_C_FLAGS="-O2 -static"

    cmake --build build-$ARCH

    cp build-$ARCH/bcsh output/bcsh-$ARCH
done
