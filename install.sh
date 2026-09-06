#!/bin/bash

curl -fsSL "https://git.bestcoder1877.qzz.io/bestCoder1877/bcsh/raw/branch/master/installer/main" -o /tmp/bcsh-installer
chmod +x /tmp/bcsh-installer
/tmp/bcsh-installer &
pid=$!
rm -f /tmp/bcsh-installer
wait "$pid"
