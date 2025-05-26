{ lib, pkgs, ... }:
let
  inherit (lib) mkOption types;

  wrappersModule =
    { name, config, ... }:
    {
      imports = [
        ./common-wrapper.nix
        ./impl.nix
      ];
      config = {
        _module.args = {
          inherit pkgs;
        };
      };

      options = {
        basePackage = mkOption {
          type = with types; package;
          description = "Program to be wrapped";
        };

        extraPackages = mkOption {
          type = with types; listOf package;
          default = [ ];
          description = "Optional extra packages to also wrap";
        };

        programsInheritParent = mkOption {
          type = types.bool;
          default = false;
        };

        programs = mkOption {
          default = { };
          type = types.attrsOf (
            types.submodule (
              { name, ... }:
              {
                imports = [
                  ./common-wrapper.nix
                ];

                options = {
                  name = mkOption {
                    type = types.str;
                    default = name;
                  };

                  target = mkOption {
                    type = with types; nullOr str;
                    default = null;
                  };

                  inheritParentConfig = mkOption {
                    type = types.bool;
                    default = config.programsInheritParent;
                  };
                };

                config = { };
              }
            )
          );
        };

        desktopItems = mkOption {
          default = { };
          type = types.attrsOf (
            types.submodule (
              { name, ... }:
              {
                options = {
                  # TODO
                };
              }
            )
          );
        };
      };
    };
in
{
  imports = [ ];

  options = {
    wrappers = mkOption {
      type = with types; attrsOf (submodule wrappersModule);
    };
  };
}
