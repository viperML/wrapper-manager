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

          The base package is used to set the wrapper name and version.
        '';
        example = lib.literalExpression "pkgs.nix";
      };

      extraPackages = mkOption {
        type = with types; listOf package;
        description = lib.mdDoc ''
          Extra packages to wrap and include in the output package.
        '';
        example = lib.literalExpression "[ pkgs.git-extras pkgs.delta ]";
        default = [];
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

      flags = mkOption {
        type = with types; listOf (separatedString " ");
        description = lib.mdDoc ''
          Flags passed to the wrapped program.
        '';
        default = [];
        example = lib.literalExpression ''
          [
            "--config ''${./config.sh}"
            "--ascii ''${./ascii}"
          ]
        '';
      };

      extraWrapperFlags = mkOption {
        type = with types; separatedString " ";
        description = lib.mdDoc ''
          Raw flags passed to makeWrapper.

          See upstream documentation: [make-wrapper.sh](https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/setup-hooks/make-wrapper.sh).
        '';
        default = "";
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
      # FIXME: pass other outputsToInstall as-is
      wrapped = lib.recursiveUpdate (pkgs.symlinkJoin ({
          paths = [config.basePackage] ++ config.extraPackages;
          nativeBuildInputs = [pkgs.makeWrapper];
          postBuild = ''
            pushd $out/bin 1>/dev/null
            for file in *; do
              echo "Wrapping $file"
              wrapProgram $file ${
              lib.concatStringsSep " " (builtins.attrValues (builtins.mapAttrs (name: value: "--set-default ${name} ${value}") config.env))
            } ${
              lib.concatMapStringsSep " " (args: "--add-flags \"${args}\"") config.flags
            } ${config.extraWrapperFlags}
            done
            popd 1>/dev/null
          '';
        }
        // lib.getAttrs [
          "name"
          "pname"
          "version"
          "meta"
        ]
        config.basePackage)) {
        meta.outputsToInstall = ["out"];
      };
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
