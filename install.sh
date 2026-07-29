#!/bin/bash

set -e

NAME="bcsh"
SOURCE="zig-out/bin/shell"
INSTALL="/usr/local/bin/$NAME"

sudo install -m 755 "$SOURCE" "$INSTALL"

if ! grep -qx "$INSTALL" /etc/shells; then
    echo "$INSTALL" | sudo tee -a /etc/shells > /dev/null
fi

cat <<EOF
Congrats! bcsh is installed!

To run it, just type:
bcsh
EOF
