#!/bin/sh
set -e

rm -rf output
mkdir output

docker build -t bcsh .

docker run --rm -it \
    -v "$(pwd)/output:/export" \
    bcsh
