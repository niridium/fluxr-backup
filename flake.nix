{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = {nixpkgs, ...}: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {inherit system;};
    fluxrPkg = pkgs.callPackage ./nix/package.nix {};
  in {
    packages.${system}.default = fluxrPkg;
    homeModules.default = {lib, ...}: {
      imports = [./nix/homeModule.nix];
      programs.fluxr.package = lib.mkDefault fluxrPkg;
    };
  };
}
