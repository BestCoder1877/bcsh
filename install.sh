#!/bin/bash

: "${BCSH_INSTALLER_PATH:=/tmp/bcsh-installer}"

if touch /tmp/testfile 2>/dev/null; then
    rm -f /tmp/testfile
else
	BCSH_INSTALLER_PATH="$HOME/bcsh-installer"
fi

curl -fsSL "https://git.bestcoder1877.qzz.io/bestCoder1877/bcsh/raw/branch/master/installer/main" -o $BCSH_INSTALLER_PATH
chmod +x $BCSH_INSTALLER_PATH
$BCSH_INSTALLER_PATH &
pid=$!
rm -f $BCSH_INSTALLER_PATH
wait "$pid"
