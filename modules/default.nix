{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption types;
  # https://github.com/nix-community/disko/blob/146f45bee02b8bd88812cfce6ffc0f933788875a/lib/default.nix#L11-L61
  subType =
    subTypes:
    lib.mkOptionType {
      name = "subType";
      description = "one of ${lib.concatStringsSep "," (lib.attrNames subTypes)}";
      check = x: lib.isAttrs x;
      merge =
        loc: defs:
        let
          evaled = lib.evalModules {
            modules = [
              {
                freeformType = types.lazyAttrsOf types.raw;
                options.type = mkOption {
                  type = types.str;
                  default = "default";
                };
              }
            ]
            ++ map (
              { value, file }:
              {
                _file = file;
                config = value;
              }
            ) defs;
          };
          inherit (evaled.config) type;
        in
        subTypes.${type}.merge loc defs;
      nestedTypes = subTypes;
    };
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
      type = types.attrsOf (subType {
        default = types.submodule [
          {
            options.type = mkOption {
              type = types.enum [ "default" ];
              readOnly = true;
              internal = true;
            };
          }
          ./wrapper.nix
          pkgs.mkWrapper.modules.wrapped
          { wrapperType = lib.mkDefault config.wrapperType; }
        ];
        custom = types.submodule [
          {
            options.type = mkOption {
              type = types.enum [ "custom" ];
              readOnly = true;
              internal = true;
            };
          }
          ./wrapper.nix
        ];
      });
      description = ''
        Wrappers to create.

        Also a collection of [modular modules](#modular-modules) that are configured as wrappers.'';
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
        paths = lib.attrValues config.build.packages;
      };

      packages = lib.mapAttrs (_: value: value.wrapped) config.wrappers;
    };
  };
}
