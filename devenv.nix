{ pkgs, lib, config, inputs, ... }:

{
  languages = {
    shell.enable = true;
    nix.enable = true;
  };
}
