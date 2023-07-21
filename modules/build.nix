{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit
    (lib)
    mkOption
    types
    ;
in {
  options = {
    build = {
      toplevel = mkOption {
        type = with types; package;
        readOnly = true;
        description = lib.mdDoc ''
          (Output) Derivation that merges all the wrappers into a single env.
        '';
      };

      packages = mkOption {
        type = with types; attrsOf package;
        readOnly = true;
        description = lib.mdDoc ''
          (Output) Set of name=drv wrapped packages. Useful for outputting in a flake's packages.
        '';
      };
    };
  };

  config = {
    build = {
      toplevel = pkgs.buildEnv {
        name = "wrapper-manager";
        paths = builtins.attrValues config.build.packages;
      };

      packages = builtins.mapAttrs (_: value: value.wrapped) config.wrappers;
    };
  };
}
