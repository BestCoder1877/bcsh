# syntax=docker/dockerfile:1.7
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    ca-certificates \
    git \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

RUN curl --fail --show-error --location --retry 5 --retry-all-errors \
    https://go.dev/dl/go1.27.3.linux-amd64.tar.gz | tar -C /usr/local -xz && \
    ln -sf /usr/local/go/bin/go /usr/bin/go && \
    ln -sf /usr/local/go/bin/gofmt /usr/bin/gofmt

RUN curl --proto '=https' --tlsv1.2 --fail --show-error --location \
    --retry 5 --retry-all-errors https://sh.rustup.rs | \
    sh -s -- -y --default-toolchain nightly --profile minimal

ENV PATH="/root/.cargo/bin:/opt/musl/bin:$PATH"

RUN rustup component add rust-src --toolchain nightly

RUN set -e; mkdir -p /opt/musl; \
    for target in \
        x86_64-linux-musl \
        i686-linux-musl \
        aarch64-linux-musl \
        armv7l-linux-musleabihf \
        riscv64-linux-musl \
        mips-linux-musl \
        mipsel-linux-musl \
        powerpc64-linux-musl \
        powerpc64le-linux-musl \
        s390x-linux-musl \
    ; do \
        curl --fail --show-error --location --retry 5 --retry-all-errors \
            "https://musl.cc/${target}-cross.tgz" -o "/tmp/${target}.tgz" && \
        tar -xf "/tmp/${target}.tgz" -C /opt/musl --strip-components=1 && \
        rm "/tmp/${target}.tgz"; \
    done && \
    for target in \
        x86_64-linux-musl \
        i686-linux-musl \
        aarch64-linux-musl \
        armv7l-linux-musleabihf \
        riscv64-linux-musl \
        mips-linux-musl \
        mipsel-linux-musl \
        powerpc64-linux-musl \
        powerpc64le-linux-musl \
        s390x-linux-musl \
    ; do \
        test -x "/opt/musl/bin/${target}-gcc" && \
        test -f "/opt/musl/${target}/lib/crt1.o" && \
        test -f "/opt/musl/${target}/lib/crti.o" && \
        test -f "/opt/musl/${target}/lib/crtn.o"; \
    done

COPY musl-gcc-wrapper.sh /opt/musl/bin/musl-gcc-wrapper.sh
RUN for cc in /opt/musl/bin/*-gcc; do \
        cp "$cc" "${cc}-real"; \
        cp /opt/musl/bin/musl-gcc-wrapper.sh "$cc"; \
        chmod +x "$cc"; \
    done && \
    printf 'int main(){return 0;}\n' > /tmp/crttest.c && \
    /opt/musl/bin/x86_64-linux-musl-gcc -c /tmp/crttest.c -o /tmp/crttest.o && \
    /opt/musl/bin/x86_64-linux-musl-gcc -static -nostartfiles -nodefaultlibs \
        crt1.o crti.o crtbegin.o /tmp/crttest.o \
        -Wl,-Bstatic -lc -Wl,-Bdynamic \
        crtend.o crtn.o -o /tmp/crttest && \
    test -x /tmp/crttest

COPY musl-gcc-wrapper.sh /opt/musl/bin/musl-gcc-wrapper.sh
RUN for cc in /opt/musl/bin/*-gcc; do \
        cp "$cc" "${cc}-real"; \
        cp /opt/musl/bin/musl-gcc-wrapper.sh "$cc"; \
        chmod +x "$cc"; \
    done && \
    printf 'int main(){return 0;}\n' > /tmp/crttest.c && \
    /opt/musl/bin/x86_64-linux-musl-gcc -c /tmp/crttest.c -o /tmp/crttest.o && \
    /opt/musl/bin/x86_64-linux-musl-gcc -static -nostartfiles -nodefaultlibs \
        crt1.o crti.o crtbegin.o /tmp/crttest.o \
        -Wl,-Bstatic -lc -Wl,-Bdynamic \
        crtend.o crtn.o -o /tmp/crttest && \
    test -x /tmp/crttest

RUN curl --fail --show-error --location --retry 5 --retry-all-errors \
    https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | tee /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY . .

RUN ./build.sh && ./installer/build.sh

ARG RELEASE_TAG=
ARG GH_REPO=bestCoder1877/bcsh

RUN --mount=type=secret,id=github_token,required=false \
    set -eu; \
    for artifact in output/bcsh-* installer/output/main-*; do \
      test -f "$artifact" && test -x "$artifact"; \
    done; \
    if [ -n "$RELEASE_TAG" ] && [ -r /run/secrets/github_token ]; then \
      export GH_TOKEN="$(cat /run/secrets/github_token)"; \
      if gh release view "$RELEASE_TAG" --repo "$GH_REPO" >/dev/null 2>&1; then \
        gh release upload "$RELEASE_TAG" output/bcsh-* installer/output/main-* --repo "$GH_REPO" --clobber; \
      else \
        gh release create "$RELEASE_TAG" output/bcsh-* installer/output/main-* \
          --repo "$GH_REPO" --generate-release-notes; \
      fi; \
    fi
