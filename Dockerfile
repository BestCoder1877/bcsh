FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    file \
    git \
    ca-certificates \
    python3 \
    cmake \
		wget \
    clang \
    llvm \
    pkg-config \
		nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | \
    sh -s -- -y --profile minimal

ENV PATH="/root/.cargo/bin:$PATH"

RUN rustup toolchain install nightly --profile minimal && \
    rustup component add rust-src --toolchain nightly

RUN rustup target add \
    x86_64-unknown-linux-musl \
    i686-unknown-linux-musl \
    aarch64-unknown-linux-musl \
    armv7-unknown-linux-musleabihf \
    arm-unknown-linux-musleabi \
    riscv64gc-unknown-linux-musl \
    powerpc64le-unknown-linux-musl

RUN rustup target add \
    powerpc64-unknown-linux-musl \
    s390x-unknown-linux-musl \
    mips-unknown-linux-musl \
    mipsel-unknown-linux-musl \
    2>/dev/null || true

RUN git clone --depth 1 https://github.com/richfelker/musl-cross-make.git /tmp/musl-cross-make

WORKDIR /tmp/musl-cross-make

RUN for target in \
    mips-unknown-linux-musl \
    mipsel-unknown-linux-musl \
    powerpc64-unknown-linux-musl \
    s390x-unknown-linux-musl \
    arm-unknown-linux-musleabi \
    armv7-unknown-linux-musleabihf \
    riscv64gc-unknown-linux-musl \
    x86_64-unknown-linux-musl \
    i686-unknown-linux-musl \
    aarch64-unknown-linux-musl \
    powerpc64le-unknown-linux-musl \
    ; do \
        make clean || true; \
        printf 'TARGET = %s\nOUTPUT = /opt/musl\n' "$target" > config.mak; \
        make -j"$(nproc)" TARGET="$target" OUTPUT=/opt/musl; \
        make install TARGET="$target" OUTPUT=/opt/musl; \
    done

ENV PATH="/opt/musl/bin:/root/.cargo/bin:$PATH"
