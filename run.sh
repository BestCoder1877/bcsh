#!/bin/bash

set -e

dir=$(pwd)

zig build

docker build -t bcsh-test .
docker run --rm -it bcsh-test su - code
