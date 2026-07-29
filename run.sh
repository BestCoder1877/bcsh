#!/bin/bash

dir=$(pwd)

cd ~/Downloads
zig build --build-file "$dir/build.zig" run
