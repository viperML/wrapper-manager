{
  lib,
  pkgs,
  ...
}: let
  inherit
    (lib)
    mkOption
    types
    ;

  wrapperOpts = {config, ...}: {
    options = {
      basePackage = mkOption {
        type = with types; package;
        description = lib.mdDoc ''
          Name of the base package to wrap.
        '';
        example = lib.literalExpression "pkgs.nix";
      };

      env = mkOption {
        type = with types; attrsOf (coercedTo anything (x: "${x}") str);
        description = lib.mdDoc ''
          Structured environment variables to set.
        '';
        default = {};
        example = {
          NIX_CONFIG = "allow-import-from-derivation = false";
        };
      };

      extraWrapperFlags = mkOption {
        type = with types; separatedString " ";
        description = lib.mdDoc ''
          Raw flags passed to makeWrapper.

          See upstream documentation: [make-wrapper.sh](https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/setup-hooks/make-wrapper.sh).
        '';
        example = "--argv0 foo --set BAR value";
      };

      wrapped = mkOption {
        type = with types; package;
        readOnly = true;
        description = lib.mdDoc ''
          (Output) Final wrapped package.
        '';
      };
    };

    config = {
      extraWrapperFlags = lib.concatStringsSep " " (builtins.attrValues (builtins.mapAttrs (name: value: "--set-default ${name} ${value}") config.env));

      wrapped = pkgs.symlinkJoin ({
          paths = [config.basePackage];
          nativeBuildInputs = [pkgs.makeWrapper];
          postBuild = ''
            for file in $out/bin/*; do
              wrapProgram $file ${config.extraWrapperFlags}
            done
          '';
        }
        // lib.getAttrs [
          "name"
          "pname"
          "version"
          "meta"
        ]
        config.basePackage);
    };
  };
in {
  options = {
    wrappers = mkOption {
      type = with types; attrsOf (submodule wrapperOpts);
      default = {};
      description = lib.mdDoc ''
        Raw wrapper configuration. You should prefer programs.<name>,
        or use this a low-level tweaker.
      '';
    };
  };

  config = {
  };
}
