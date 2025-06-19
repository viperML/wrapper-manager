{ pkgs, lib, config, ... }:
let
  inherit (lib) mkOption types;

in
{
  imports = [
    ./common-wrapper.nix
    ./wrapper-impl.nix
  ];

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

    programs = mkOption {
      default = { };
      description = "Programs to wrap";
      type = types.attrsOf (
        types.submoduleWith {
          modules = [
            ./common-wrapper.nix
            (
              { name, ... }:
              {
                options = {
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
                };

                config = {
                  wrapperType = lib.mkDefault config.wrapperType;
                };
              }
            )
          ];
        }
      );
    };
  };
}
