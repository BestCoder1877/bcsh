#!/bin/sh
set -e

cmake -S . -B build-x86_64 \
    -DCMAKE_C_COMPILER=gcc \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_FLAGS="-O2 -static"
cmake --build build-x86_64
chmod +x ./build-x86_64/bcsh
./build-x86_64/bcsh
rm -rf ./build-x86_64
