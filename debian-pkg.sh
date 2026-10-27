#!/bin/sh
set -e

case "${1:-}" in
    ""|all)
        ARCHES="x86_64 i386 arm64 armhf armel riscv64 mips mipsel ppc64 ppc64le s390x"
        ;;
    *)
        ARCHES="$*"
        ;;
esac

dpkg_arch() {
    case "$1" in
        x86_64) echo "amd64" ;;
        i386)   echo "i386" ;;
        *)      echo "$1" ;;
    esac
}

PKGNAME=bcsh
VERSION=$(awk '
    /^\[/ { in_pkg = ($0 == "[package]") }
    in_pkg && /^version/ { sub(/^version *= *"?/, ""); sub(/".*/, ""); print; exit }
' Cargo.toml)
if [ -z "$VERSION" ]; then
    echo "debian-pkg.sh: could not determine version from Cargo.toml" >&2
    exit 1
fi

DESTDIR="${DEB_OUTDIR:-output/deb}"
mkdir -p "$DESTDIR"

GIT_SHA="${GIT_SHA:-$(git rev-parse --short HEAD 2>/dev/null || true)}"
GIT_COUNT="${GIT_COUNT:-$(git rev-list --count HEAD 2>/dev/null || true)}"
if [ -z "$GIT_SHA" ] || [ -z "$GIT_COUNT" ]; then
    echo "debian-pkg.sh: could not determine git sha/count" >&2
    exit 1
fi
GIT_SHA="$(printf '%s' "$GIT_SHA" | cut -c1-7)"
PKGVER="${VERSION}~git${GIT_COUNT}.${GIT_SHA}"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

for arch in $ARCHES; do
    BIN="output/bcsh-${arch}"
    if [ ! -f "$BIN" ]; then
        echo "debian-pkg.sh: skipping ${arch}: ${BIN} not found" >&2
        continue
    fi
    DEB_ARCH="$(dpkg_arch "$arch")"

    ROOT="$TMP/root"
    rm -rf "$ROOT"
    mkdir -p "$ROOT/DEBIAN" "$ROOT/usr/bin"
    chmod 0755 "$ROOT/DEBIAN"

    cat > "$ROOT/DEBIAN/control" <<EOF
Package: ${PKGNAME}
Version: ${PKGVER}
Section: shells
Priority: optional
Architecture: ${DEB_ARCH}
Maintainer: bestCoder1877 <datoohamza@outlook.com>
Description: The Best Coder Shell - a small shell written in Rust
 BCSH ("The Best Coder Shell") is a small, lightweight shell written in
 Rust, designed to be simple, fast, readable, and easy to modify.
EOF

    cat > "$ROOT/DEBIAN/postinst" <<'EOF'
#!/bin/sh
set -e
#DEBHELPER#
if [ -x /usr/bin/bcsh ]; then
    if ! grep -qx '/usr/bin/bcsh' /etc/shells 2>/dev/null; then
        echo '/usr/bin/bcsh' >> /etc/shells
    fi
fi
EOF
    chmod 755 "$ROOT/DEBIAN/postinst"

    cat > "$ROOT/DEBIAN/prerm" <<'EOF'
#!/bin/sh
set -e
#DEBHELPER#
EOF
    chmod 755 "$ROOT/DEBIAN/prerm"

    install -Dm755 "$BIN" "$ROOT/usr/bin/bcsh"

    DEB="${DESTDIR}/${PKGNAME}_${PKGVER}_${DEB_ARCH}.deb"
    dpkg-deb -b "$ROOT" "$DEB"
    echo "debian-pkg.sh: built ${DEB}"
done