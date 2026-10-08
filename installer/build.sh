#!/bin/sh
set -e
cd "$(dirname "$0")"
mkdir -p output
for arch in amd64 386 arm64 arm riscv64 mips mipsle ppc64 ppc64le s390x; do
    GOOS=linux GOARCH="$arch" CGO_ENABLED=0 go build -o "output/main-$arch" .
    echo "Built output/main-$arch"
done
