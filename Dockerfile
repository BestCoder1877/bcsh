FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    ca-certificates \
    git \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://go.dev/dl/go1.27.3.linux-amd64.tar.gz | tar -C /usr/local -xz && \
    ln -sf /usr/local/go/bin/go /usr/bin/go && \
    ln -sf /usr/local/go/bin/gofmt /usr/bin/gofmt

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | \
    sh -s -- -y --default-toolchain nightly --profile minimal

ENV PATH="/root/.cargo/bin:/opt/musl/bin:$PATH"

RUN rustup component add rust-src --toolchain nightly

RUN for t in \
        x86_64-unknown-linux-musl \
        i686-unknown-linux-musl \
        aarch64-unknown-linux-musl \
        armv7-unknown-linux-musleabihf \
        arm-unknown-linux-musleabi \
        riscv64gc-unknown-linux-musl \
        mips-unknown-linux-musl \
        mipsel-unknown-linux-musl \
        powerpc64le-unknown-linux-musl \
        powerpc64-unknown-linux-musl \
        s390x-unknown-linux-musl \
    ; do \
        rustup target add --toolchain nightly "$t" \
            || echo "WARNING: no prebuilt std for target $t; skipping" ; \
    done

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

RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | tee /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY . .

RUN ./build.sh && ./installer/build.sh

ARG GH_TOKEN=

RUN TAG=$(git tag --points-at HEAD 2>/dev/null | head -n1); \
    if [ -z "$TAG" ]; then \
      echo "No tag points at HEAD; skipping release publish."; \
    elif gh release view "$TAG" >/dev/null 2>&1; then \
      echo "Release $TAG exists; uploading assets."; \
      gh release upload "$TAG" output/bcsh-* installer/output/main-* --clobber; \
    else \
      echo "Creating release $TAG."; \
      gh release create "$TAG" output/bcsh-* installer/output/main-* --generate-release-notes; \
    fi
