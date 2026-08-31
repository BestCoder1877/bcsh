FROM node:22-trixie

RUN apt-get update && apt-get install -y \
    cmake \
    make \
    gcc \
    g++ \
    musl-tools \
    git \
    curl \
    file \
    sudo \
    passwd \
    && rm -rf /var/lib/apt/lists/*

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

ENV PATH="/root/.cargo/bin:/opt/musl/bin:$PATH"

RUN git clone --depth 1 https://github.com/richfelker/musl-cross-make.git /tmp/musl-cross-make

RUN set -eux; \
    cd /tmp/musl-cross-make; \
    for target in \
        x86_64-linux-musl \
        i486-linux-musl \
        aarch64-linux-musl \
        arm-linux-musleabihf \
        arm-linux-musleabi \
        riscv64-linux-musl \
        mips-linux-musl \
        mipsel-linux-musl \
        powerpc64-linux-musl \
        powerpc64le-linux-musl \
        s390x-linux-musl \
    ; do \
        echo "Building $target"; \
        printf 'TARGET = %s\nOUTPUT = /opt/musl\n' "$target" > config.mak; \
        make -j"$(nproc)"; \
        make install; \
        rm -rf build; \
    done

RUN rustup target add \
    x86_64-unknown-linux-musl \
    i686-unknown-linux-musl \
    aarch64-unknown-linux-musl \
    armv7-unknown-linux-musleabihf \
    arm-unknown-linux-musleabi \
    riscv64gc-unknown-linux-musl \
    mips-unknown-linux-musl \
    mipsel-unknown-linux-musl \
    powerpc64-unknown-linux-musl \
    powerpc64le-unknown-linux-musl \
    s390x-unknown-linux-musl

RUN mkdir -p /root/.cargo && cat > /root/.cargo/config.toml <<'EOF'
[target.x86_64-unknown-linux-musl]
linker = "/opt/musl/bin/x86_64-linux-musl-gcc"

[target.i686-unknown-linux-musl]
linker = "/opt/musl/bin/i486-linux-musl-gcc"

[target.aarch64-unknown-linux-musl]
linker = "/opt/musl/bin/aarch64-linux-musl-gcc"

[target.armv7-unknown-linux-musleabihf]
linker = "/opt/musl/bin/arm-linux-musleabihf-gcc"

[target.arm-unknown-linux-musleabi]
linker = "/opt/musl/bin/arm-linux-musleabi-gcc"

[target.riscv64gc-unknown-linux-musl]
linker = "/opt/musl/bin/riscv64-linux-musl-gcc"

[target.mips-unknown-linux-musl]
linker = "/opt/musl/bin/mips-linux-musl-gcc"

[target.mipsel-unknown-linux-musl]
linker = "/opt/musl/bin/mipsel-linux-musl-gcc"

[target.powerpc64-unknown-linux-musl]
linker = "/opt/musl/bin/powerpc64-linux-musl-gcc"

[target.powerpc64le-unknown-linux-musl]
linker = "/opt/musl/bin/powerpc64le-linux-musl-gcc"

[target.s390x-unknown-linux-musl]
linker = "/opt/musl/bin/s390x-linux-musl-gcc"
EOF
