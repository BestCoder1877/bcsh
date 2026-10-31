# Maintainer: bestCoder1877 <datoohamza@outlook.com>
pkgname=bcsh
pkgver=r1.a1b2c3d
pkgrel=1
pkgdesc="The Best Coder Shell - a small shell written in Rust"
arch=('x86_64' 'aarch64')
url="https://github.com/bestCoder1877/bcsh"
license=('MIT')
depends=('glibc')
makedepends=('cargo' 'git')
source=("git+${url}.git")
b2sums=('SKIP')

pkgver() {
  cd "$srcdir/$pkgname"
  printf "r%s.%s" "$(git rev-list --count HEAD)" "$(git rev-parse --short HEAD)"
}

build() {
  cd "$srcdir/$pkgname"
  cargo build --release --locked
}

package() {
  cd "$srcdir/$pkgname"
  install -Dm755 target/release/$pkgname "$pkgdir/usr/bin/$pkgname"
}
