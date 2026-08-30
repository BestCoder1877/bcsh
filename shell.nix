{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  packages = with pkgs; [
    cmake
		gcc
    gnumake
    glibc.static
  ];
}
