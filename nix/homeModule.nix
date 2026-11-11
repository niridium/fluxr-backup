{
  config,
  lib,
  ...
}: let
  cfg = config.programs.fluxr;
in {
  options.programs.fluxr = {
    enable = lib.mkEnableOption "fluxr, a backup system";
    package = lib.mkPackageOption "fluxr";
    settings = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
    };
  };
  config = let
    configFiles = builtins.listToAttrs map (file: lib.nameValuePair "xdg.configFile.fluxr/${file}.source" "${file}") cfg.settings;
  in
    lib.mkIf cfg {
    }
    // configFiles;
}
