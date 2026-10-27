{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  name = "bcsh-dev";

  nativeBuildInputs = with pkgs; [
    gitFull
    coreutils
    diffutils
    cargo
    rustc
    rustfmt
    clippy
    rust-analyzer
  ];

 	shellHook = ''
 		clear
		cargo run
 	'';
 }
}
