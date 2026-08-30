{
  description = "The Best Coder Shell";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  outputs = { nixpkgs, ... }:
    let
      systems = [
        "x86_64-linux"
        "i686-linux"
        "aarch64-linux"
        "armv7l-linux"
        "armv6l-linux"
        "mips-linux"
        "mipsel-linux"
        "powerpc64-linux"
        "powerpc64le-linux"
        "riscv64-linux"
        "s390x-linux"
      ];
      forAllSystems = f:
        nixpkgs.lib.genAttrs systems (system:
          f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (pkgs: {
        default = pkgs.stdenv.mkDerivation {
          pname = "bcsh";
          version = "unstable";
          src = ./.;
          nativeBuildInputs = [ pkgs.cmake ];
          configurePhase = ''
            cmake -S . -B build \
              -DCMAKE_BUILD_TYPE=Release
          '';
          buildPhase = ''
            cmake --build build
          '';
          installPhase = ''
            mkdir -p $out/bin
            cp build/bcsh $out/bin/bcsh
          '';
        };
      });
    };
}
