{
  description = "The Best Coder Shell";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs =
    { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        packages.default = pkgs.rustPlatform.buildRustPackage {
          pname = "bcsh";
          version = "unstable";
          src = ./.;
          cargoLock.lockFile = ./Cargo.lock;
          buildType = "release";
          installPhase = ''
            mkdir -p $out/bin
            cp target/${pkgs.stdenv.hostPlatform.rust.rustcTarget}/release/bcsh $out/bin/bcsh
          '';
        };
      }
    );
}
