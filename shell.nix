{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  name = "bcsh-dev";

  nativeBuildInputs = with pkgs; [
		devenv
  ];

	shellHook = ''
		clear
		devenv shell
	'';
}
