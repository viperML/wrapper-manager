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
          Program to be wrapped.
        '';
        example = lib.literalExpression "pkgs.nix";
      };

      extraPackages = mkOption {
        type = with types; listOf package;
        description = lib.mdDoc ''
          Extra packages to also wrap.
        '';
        example = lib.literalExpression "[ pkgs.git-extras pkgs.delta ]";
        default = [];
      };

      env = mkOption {
        type = with types; attrsOf (coercedTo anything (x: "${x}") str);
        description = lib.mdDoc ''
          Structured environment variables.
        '';
        default = {};
        example = {
          NIX_CONFIG = "allow-import-from-derivation = false";
        };
      };

      flags = mkOption {
        type = with types; listOf (separatedString " ");
        description = lib.mdDoc ''
          Flags passed to all the wrapped programs.
        '';
        default = [];
        example = lib.literalExpression ''
          [
            "--config ''${./config.sh}"
            "--ascii ''${./ascii}"
          ]
        '';
      };

      pathAdd = mkOption {
        type = with types; listOf package;
        description = lib.mdDoc ''
          Packages to append to PATH.
        '';
        default = [];
        example = lib.literalExpression "[ pkgs.starship ]";
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
      wrapped = let
        result =
          pkgs.symlinkJoin ({
              paths = [config.basePackage] ++ config.extraPackages;
              nativeBuildInputs = [pkgs.makeWrapper];
              postBuild = ''
                for file in $out/bin/*; do
                  echo "Wrapping $file"
                  wrapProgram $file ${
                  lib.concatStringsSep " " (builtins.attrValues (builtins.mapAttrs (name: value: "--set-default ${name} ${value}") config.env))
                } ${
                  lib.concatMapStringsSep " " (args: "--add-flags \"${args}\"") config.flags
                } ${
                  lib.concatMapStringsSep " " (p: "--prefix PATH : ${p}/bin") config.pathAdd
                } ${config.extraWrapperFlags}
                done

                cd $out/bin
                for exe in *; do
                  for file in $out/share/applications/*; do
                    echo "Fixing $file"
                    sed -i "s:/nix/store/.*/bin/$exe :$out/bin/$exe :" "$file"
                  done
                done


                # I don't know of a better way to create a multe-output derivation for symlinkJoin
                # So if the packages have man, just link them into $out
                ${
                  lib.concatMapStringsSep "\n"
                  (p:
                    if lib.hasAttr "man" p
                    then "${pkgs.xorg.lndir}/bin/lndir -silent ${p.man} $out"
                    else "#")
                  ([config.basePackage] ++ config.extraPackages)
                }
              '';
            }
            // lib.getAttrs [
              "name"
              "meta"
            ]
            config.basePackage)
          // (lib.optionalAttrs (lib.hasAttr "pname" config.basePackage) {
            inherit (config.basePackage) pname;
          })
          // (lib.optionalAttrs (lib.hasAttr "version" config.basePackage) {
            inherit (config.basePackage) version;
          });
      in
        lib.recursiveUpdate result {
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
        Wrapper configuration. See the suboptions for configuration.
      '';
    };
  };

  config = {
  };
}
