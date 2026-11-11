{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = {
    self,
    nixpkgs,
    ...
  }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {inherit system;};
  in {
    packages.${system}.default = pkgs.callPackage ./nix/package.nix {};
    homeModules.default = {
      pkgs,
      lib,
      ...
    }: {
      imports = [./nix/homeModule.nix];
      programs.fluxr.package = lib.mkDefault self.packages.${pkgs.stdenv.hostPlatform.system}.default;
    };
  };
}
