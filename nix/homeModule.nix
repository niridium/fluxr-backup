{
  config,
  lib,
  ...
}: let
  cfg = config.programs.fluxr;
  configFiles = builtins.listToAttrs (map (file: lib.nameValuePair "xdg.configFile.fluxr/${file}.source" "${file}") cfg.settings);
in {
  options.programs.fluxr = {
    enable = lib.mkEnableOption "fluxr, a backup system";
    package = lib.mkPackageOption "fluxr";
    settings = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
    };
  };
  config =
    lib.mkIf cfg.enable
    {home.packages = [cfg.package];}
    // configFiles;
}
