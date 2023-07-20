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
          Name of the base package to wrap
        '';
      };

      env = mkOption {
        type = with types; attrsOf anything;
        description = lib.mdDoc ''
          Structured environment variables to set
        '';
        default = {};
        example = {
          NIX_CONFIG = "allow-import-from-derivation = false";
        };
      };

      extraWrapperFlags = mkOption {
        type = with types; separatedString " ";
        description = lib.mdDoc ''
          Raw flags passed to makeWrapper.sh

          See upstream doc: https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/setup-hooks/make-wrapper.sh
        '';
      };

      wrapper = mkOption {
        type = with types; package;
        readOnly = true;
        description = lib.mdDoc ''
          Generated wrapper package
        '';
      };
    };

    config = {
      extraWrapperFlags = lib.concatStringsSep " " (builtins.attrValues (builtins.mapAttrs (name: value: "--set-default ${name} ${value}") config.env));

      wrapper = pkgs.symlinkJoin {
        inherit (config.basePackage) name;
        paths = [config.basePackage];
        nativeBuildInputs = [pkgs.makeWrapper];
        postBuild = ''
          for file in $out/bin/*; do
            wrapProgram $file ${config.extraWrapperFlags}
          done
        '';
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
    wrappers._test = {
      env.FOO = "foo";
      env.BAR = "bar";
      basePackage = pkgs.hello;
    };
  };
}
