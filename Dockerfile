FROM node:22-trixie

RUN apt-get update && apt-get install -y \
    cmake \
    make \
    gcc \
    gcc-i686-linux-gnu \
    gcc-aarch64-linux-gnu \
    gcc-arm-linux-gnueabihf \
    gcc-arm-linux-gnueabi \
    gcc-riscv64-linux-gnu \
    gcc-mips-linux-gnu \
    gcc-mipsel-linux-gnu \
    gcc-powerpc64-linux-gnu \
    gcc-powerpc64le-linux-gnu \
    gcc-s390x-linux-gnu \
    file \
    sudo \
    curl \
    passwd \
    && rm -rf /var/lib/apt/lists/*
