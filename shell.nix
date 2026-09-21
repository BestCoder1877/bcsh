{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  name = "bcsh-dev";

  nativeBuildInputs = with pkgs; [
    rustup
    git
    cargo
    coreutils
    diffutils
    rustfmt
    clippy
  ];

  # Environment variables for development
  RUST_BACKTRACE = "1";
  CARGO_TARGET_DIR = "./target";
  RUSTUP_TOOLCHAIN = "nightly";

  # Shell hook to show welcome message and ensure nightly toolchain
  shellHook = ''
    rustup install nightly
    rustup default nightly
		clear
		cargo run
  '';
}
