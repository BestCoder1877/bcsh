#!/bin/bash

set -e

NAME="bcsh"
INSTALL="/bin/$NAME"
URL=""

if [ -n "$BCSH_DEV_MODE" ]; then
	cp zig-out/bin/shell $NAME
else
	curl -L "$URL" -o "bcsh"
fi

sudo install -m 755 "$NAME" "$INSTALL"

if ! grep -qx "$INSTALL" /etc/shells; then
    echo "$INSTALL" | sudo tee -a /etc/shells > /dev/null
fi

cat <<EOF
Congrats! bcsh is installed!

To run it, just type:
bcsh
EOF
