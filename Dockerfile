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
    nodejs \
    npm \
    llvm \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Install Rust and set nightly as default to ensure all targets use the correct toolchain
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | \
    sh -s -- -y --default-toolchain nightly --profile minimal

ENV PATH="/root/.cargo/bin:/opt/musl/bin:$PATH"

RUN rustup component add rust-src --toolchain nightly

RUN rustup target add --toolchain nightly \
    x86_64-unknown-linux-musl \
    i686-unknown-linux-musl \
    aarch64-unknown-linux-musl \
    armv7-unknown-linux-musleabihf \
    arm-unknown-linux-musleabi \
    riscv64gc-unknown-linux-musl \
    powerpc64le-unknown-linux-musl \
    powerpc64-unknown-linux-musl

# Install musl cross compilers from pre-built binaries (fast)
RUN mkdir -p /opt/musl && for target in \
    x86_64-linux-musl \
    i686-linux-musl \
    aarch64-linux-musl \
    arm-linux-musleabi \
    armv7l-linux-musleabihf \
    riscv64-linux-musl \
    mips-linux-musl \
    mipsel-linux-musl \
    powerpc64-linux-musl \
    powerpc64le-linux-musl \
    s390x-linux-musl \
    ; do \
    curl -sSL https://musl.cc/${target}-cross.tgz | tar -xz -C /opt/musl --strip-components=1; \
    done
