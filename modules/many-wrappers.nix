{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption types;
in
{
  options = {
    wrapperType = mkOption {
      description = "Which wrapper type to use by default for all wrappers.";
      type = types.enum [
        "shell"
        "binary"
      ];
      default = "binary";
      example = "shell";
    };

    wrappers = mkOption {
      type = types.attrsOf (
        types.submoduleWith {
          modules = [
            ./wrapper.nix
            {
              wrapperType = lib.mkDefault config.wrapperType;
            }
          ];
          specialArgs = {
            inherit pkgs;
          };
        }
      );
      description = "Wrappers to create.";
      example = lib.literalExpression ''
        {
          hello = {
            basePackage = pkgs.hello;
            prependFlags = [
              "-g"
              "Hi"
            ];
          };
        }
      '';
    };

    build = {
      toplevel = mkOption {
        type = types.package;
        readOnly = true;
        description = ''
          (Read-only) Package that merges all the wrappers into a single derivation.
          You may want to use build.packages instead.
        '';
      };

      packages = mkOption {
        type = with types; attrsOf package;
        readOnly = true;
        description = ''
          (Read-only) Attribute set of name=pkg, for every wrapper.
        '';
      };
    };
  };

  config = {
    build = {
      toplevel = pkgs.buildEnv {
        name = "wrapper-manager-bundle";
        paths = builtins.attrValues config.build.packages;
      };

      packages = builtins.mapAttrs (_: value: value.wrapped) config.wrappers;
    };
  };
}
