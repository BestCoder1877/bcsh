#!/bin/sh
set -e

cd "$(dirname "$0")"

mkdir -p output

targets="x86_64-unknown-linux-musl i686-unknown-linux-musl aarch64-unknown-linux-musl armv7-unknown-linux-musleabihf arm-unknown-linux-musleabi riscv64gc-unknown-linux-musl mips-unknown-linux-musl mipsel-unknown-linux-musl powerpc64le-unknown-linux-musl powerpc64-unknown-linux-musl s390x-unknown-linux-musl"

for target in $targets; do
    case "$target" in
        x86_64-unknown-linux-musl)          out=bcsh-x86_64 ;;
        i686-unknown-linux-musl)            out=bcsh-i386 ;;
        aarch64-unknown-linux-musl)         out=bcsh-arm64 ;;
        armv7-unknown-linux-musleabihf)     out=bcsh-armhf ;;
        arm-unknown-linux-musleabi)         out=bcsh-armhf ;;
        riscv64gc-unknown-linux-musl)       out=bcsh-riscv64 ;;
        mips-unknown-linux-musl)            out=bcsh-mips ;;
        mipsel-unknown-linux-musl)          out=bcsh-mipsle ;;
        powerpc64le-unknown-linux-musl)     out=bcsh-ppc64le ;;
        powerpc64-unknown-linux-musl)       out=bcsh-ppc64 ;;
        s390x-unknown-linux-musl)           out=bcsh-s390x ;;
    esac

    cargo build --release --target "$target" || { echo "WARNING: skipping $target (no prebuilt std)"; continue; }
    cp "target/$target/release/bcsh" "output/$out"
    echo "Built output/$out"
done