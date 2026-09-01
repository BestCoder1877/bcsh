{
  description = "The Best Coder Shell";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  outputs =
    { nixpkgs, ... }:
    let
      system = builtins.currentSystem;
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      packages.${system}.default = pkgs.rustPlatform.buildRustPackage {
        pname = "bcsh";
        version = "unstable";
        src = ./.;
        cargoLock.lockFile = ./Cargo.lock;
        buildType = "release";
        RUSTFLAGS = "-C target-feature=+crt-static";
        installPhase = ''
          mkdir -p $out/bin
          cp target/release/bcsh $out/bin/bcsh
        '';
      };
    };
}
