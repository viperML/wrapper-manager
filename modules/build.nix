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
          Final package composed of all the wrappers.
        '';
      };
    };
  };

  config = {
    build = {
      toplevel = pkgs.buildEnv {
        name = "wrapper-manager";
        paths = builtins.attrValues (builtins.mapAttrs (_: value: value.wrapped) config.wrappers);
      };
    };
  };
}
