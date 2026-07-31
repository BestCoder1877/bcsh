#!/bin/bash

set -e

NAME="bcsh"
INSTALL="/bin/$NAME"
ARCH=$(uname -m)

case "$ARCH" in
    x86_64)
        BINARY="bcsh-x86_64"
        ;;
    aarch64|arm64)
        BINARY="bcsh-arm64"
        ;;
    armv7l|armhf)
        BINARY="bcsh-armhf"
        ;;
    armv6l|armel)
        BINARY="bcsh-armel"
        ;;
    i386|i686)
        BINARY="bcsh-i386"
        ;;
    mips)
        BINARY="bcsh-mips"
        ;;
    mipsel)
        BINARY="bcsh-mipsel"
        ;;
    ppc64)
        BINARY="bcsh-ppc64"
        ;;
    ppc64le)
        BINARY="bcsh-ppc64le"
        ;;
    riscv64)
        BINARY="bcsh-riscv64"
        ;;
    s390x)
        BINARY="bcsh-s390x"
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

URL="https://gitlab.com/bestCoder1877/bcsh/-/raw/master/output/$BINARY"

curl -L "$URL" -o bcsh
chmod +x bcsh

if [ -z "$BCSH_DEV_MODE" ]; then
	curl -L "$URL" -o "bcsh"
else
	cp ./output/bcsh-x86_64 ./bcsh
fi

if [ "$(id -u)" -eq 0 ]; then
    install -m 755 "$NAME" "$INSTALL"
else
    sudo install -m 755 "$NAME" "$INSTALL"
fi

if ! grep -qx "$INSTALL" /etc/shells; then
    echo "$INSTALL" | sudo tee -a /etc/shells > /dev/null
fi

rm bcsh

cat <<EOF
Congrats! bcsh is installed!

To run it, just type:
bcsh

If you want this to be your default shell run:
chsh -s /bin/bcsh
EOF
