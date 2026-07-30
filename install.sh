#!/bin/bash

set -e

NAME="bcsh"
INSTALL="/bin/$NAME"
URL="https://gitlab.com/bestCoder1877/bcsh/-/raw/master/bcsh"

if [ -n "$BCSH_DEV_MODE" ]; then
	cp zig-out/bin/shell $NAME
else
	curl -L "$URL" -o "bcsh"
fi

if [ "$(id -u)" -eq 0 ]; then
    install -m 755 "$NAME" "$INSTALL"
else
    sudo install -m 755 "$NAME" "$INSTALL"
fi

if ! grep -qx "$INSTALL" /etc/shells; then
    echo "$INSTALL" | sudo tee -a /etc/shells > /dev/null
fi

cat <<EOF
Congrats! bcsh is installed!

To run it, just type:
bcsh

If you want this to be your default shell run:
chsh -s /bin/bcsh
EOF
