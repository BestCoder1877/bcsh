#!/bin/sh
set -e

mkdir -p output

for target in \
    "x86_64 x86_64-unknown-linux-musl" \
    "i386 i686-unknown-linux-musl" \
    "arm64 aarch64-unknown-linux-musl" \
    "armhf armv7-unknown-linux-musleabihf" \
    "armel arm-unknown-linux-musleabi" \
    "riscv64 riscv64gc-unknown-linux-musl" \
    "mips mips-unknown-linux-musl" \
    "mipsel mipsel-unknown-linux-musl" \
    "ppc64 powerpc64-unknown-linux-musl" \
    "ppc64le powerpc64le-unknown-linux-musl" \
    "s390x s390x-unknown-linux-musl"
do
    set -- $target
    ARCH=$1
    TARGET=$2
    case "$TARGET" in
        mips-unknown-linux-musl|mipsel-unknown-linux-musl|s390x-unknown-linux-musl)
            cargo +nightly build -Z build-std=std,panic_abort --release --target "$TARGET"
            ;;
        *)
            cargo build --release --target "$TARGET"
            ;;
    esac
    cp "target/$TARGET/release/bcsh" "output/bcsh-$ARCH"
    file "output/bcsh-$ARCH"
done
