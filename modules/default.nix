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
          description = "Whether to inherit the parent's programs";
        };

        programs = mkOption {
          default = { };
          description = "Programs to wrap";
          type = types.attrsOf (
            types.submodule (
              { name, ... }:
              {
                imports = [
                  ./common-wrapper.nix
                ];

                options = {
                  wrap = mkOption {
                    type = types.bool;
                    default = true;
                    description = "Whether to wrap the program";
                  };

                  name = mkOption {
                    type = types.str;
                    default = name;
                    description = "Name of the program";
                  };

                  target = mkOption {
                    type = with types; nullOr str;
                    default = null;
                    description = "Target of the program";
                  };

                  inheritParentConfig = mkOption {
                    type = types.bool;
                    default = config.programsInheritParent;
                    description = "Whether to inherit the parent's config";
                  };
                };

                config = { };
              }
            )
          );
        };

        desktopItems = mkOption {
          default = { };
          description = "Desktop items to wrap";
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
      description = "Wrappers to create";
    };
  };
}
