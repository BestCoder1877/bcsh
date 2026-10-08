#!/bin/bash

: "${BCSH_INSTALLER_PATH:=/tmp/bcsh-installer}"

if touch /tmp/testfile 2>/dev/null; then
    rm -f /tmp/testfile
else
	BCSH_INSTALLER_PATH="$HOME/bcsh-installer"
fi

ARCH=$(uname -m)
case "$ARCH" in
	x86_64) ARCH=amd64 ;;
	i386|i486|i586|i686) ARCH=386 ;;
	aarch64) ARCH=arm64 ;;
	armv7l|armv6l) ARCH=arm ;;
esac

curl -fsSL "https://git.bestcoder1877.qzz.io/bestCoder1877/bcsh/raw/branch/master/installer/output/main-$ARCH" -o $BCSH_INSTALLER_PATH
chmod +x $BCSH_INSTALLER_PATH
$BCSH_INSTALLER_PATH &
pid=$!
rm -f $BCSH_INSTALLER_PATH
wait "$pid"
