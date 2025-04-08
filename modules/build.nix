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
        description =   ''
          (Output) Derivation that merges all the wrappers into a single package.
        '';
      };

      packages = mkOption {
        type = with types; attrsOf package;
        readOnly = true;
        description =   ''
          (Output) Attribute set of name=pkg. Useful for adding them to a flake's packages output.
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
