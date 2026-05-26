{pkgs, ...}: {
  packages = with pkgs; [
    git
    git-conventional-commits
  ];
  languages = {
    shell.enable = true;
    nix.enable = true;
  };
  git-hooks = {
    hooks = {
      alejandra.enable = true;
      deadnix.enable = true;

      git-conventional-commits = {
        enable = true;
        name = "git-conventional-commits";
        entry = "git-conventional-commits commit-msg-hook";
        stages = ["commit-msg"];
        language = "node";
      };
    };
  };
}
