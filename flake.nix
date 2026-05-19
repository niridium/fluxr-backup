{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs =
    {
      self,
      nixpkgs,
      ...
    }:
    {
    #   devShells.x86_64-linux = {
    #     default =
    #       let
    #         system = "x86_64-linux";
    #         pkgs = import nixpkgs { inherit system; };
    #       in
    #       with pkgs;
    #       mkShell {
    #         packages = [
    #           cachix
    #           git-conventional-commits
    #           nil
    #           nixd
    #           nixfmt-tree
    #           pre-commit
    #           shellcheck
    #           shfmt

    #           zenity
    #         ];
    #       };
    #   };
    };
}
