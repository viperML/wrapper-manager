{ config, lib, pkgs, ... }:
let
  inherit (lib) mkOption types;
in
{
  options = {
    wrapperType = mkOption {
      type = types.enum ["shell" "binary"];
      default = "binary";
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
      description = "Wrappers to create";
    };
  };
}
