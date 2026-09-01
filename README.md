> **WARNING:** Still In Development

# The Best Coder Shell

a full shell that is under 1MB written in one rust file.

## Installation

to install ensure you have bash and curl installed and run: 

```bash
curl -sL https://git.bestcoder1877.qzz.io/bestCoder1877/bcsh/raw/branch/master/install.sh | bash
```

## NixOS Installation

Add this to your flake.nix

```nix
bcsh.url = "git+https://git.bestcoder1877.qzz.io/bestCoder1877/bcsh";
```
And then add this to systemPackages

```nix
inputs.bcsh.packages.${pkgs.system}.default
```

## Manual Installation

1. download the correct shell for your cpu architecture
2. chmod +x it
3. run install -m 755 <your binary name here> /bin/bcsh as root
4. add /bin/bcsh to /etc/shells (edit the file as root)
