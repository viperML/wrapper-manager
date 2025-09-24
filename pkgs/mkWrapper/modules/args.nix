{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkOption types;
in
{
  imports = [ ./common-args.nix ];

  options = {
    basePackage = mkOption {
      type = types.package;
      description = "Program to be wrapped.";
    };

    extraPackages = mkOption {
      type = with types; listOf package;
      default = [ ];
      description = "Optional extra packages to also wrap.";
    };

    programs = mkOption {
      type = types.attrsOf (
        types.submoduleWith {
          modules = [
            ./common-args.nix
            (
              { name, ... }:
              {
                options = {
                  name = mkOption {
                    type = types.str;
                    default = name;
                    description = "Name of the program.";
                  };

                  target = mkOption {
                    type = with types; nullOr str;
                    default = null;
                    description = "Target of the program.";
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
      default = { };
      description = "Wrap specific binaries with specific options. You may use it to skip wrapping some program.";
      example = lib.literalExpression ''
        {
          supervim = {
            target = "neovim";
          };

          git = {
            envVars.GIT_CONFIG.value = ./gitconfig;
          };

          # Don't wrap scalar
          scalar = { };
        }
      '';
    };

    postBuild = mkOption {
      type = types.str;
      default = "";
      description = "Raw commands to execute after the wrapping process has finished.";
      example = ''
        echo "Running sanity check"
        $out/bin/nvim '+q'
      '';
    };
  };
}
