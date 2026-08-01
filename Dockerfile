FROM debian:trixie

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

WORKDIR /app

COPY . .

RUN chmod +x build.sh

RUN ./build.sh

RUN cp output/bcsh-x86_64 /bin/bcsh \
    && chmod +x /bin/bcsh

RUN echo "/bin/bcsh" >> /etc/shells

RUN useradd -m -s /bin/bcsh code \
    && passwd -d code \
    && echo "code ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/code

WORKDIR /home/code

USER code
