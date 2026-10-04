{
  pkgs,
  ...
}:
{
  packages = with pkgs; [
    gitFull
    coreutils
    diffutils
  ];
  languages.rust = {
    enable = true;
    channel = "nightly";
    components = [
      "rustfmt"
      "clippy"
    ];
  };
  enterShell = ''
		clear
  '';
}
