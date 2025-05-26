{
  lib,
  config,
  ...
}:
let
  inherit (lib) mkOption types flatten;
  inherit (builtins) attrValues;
  flagsType = with types; listOf (coercedTo anything (x: "${x}") str);
in
{
  imports = [
    (lib.mkAliasOptionModuleMD [ "flags" ] [ "prependFlags" ])
  ];

  options = {
    wrapFlags = mkOption {
      type = flagsType;
      default = [ ];
      description = "Flags passed to makeWrapper.";
    };
    binaryWrapper = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to use a binary wrapper.";
    };
    appendFlags = mkOption {
      type = flagsType;
      default = [ ];
      description = "Flags passed after any arguments to the wrapped program.";
    };
    prependFlags = mkOption {
      type = flagsType;
      default = [ ];
      description = "Flags passed before any arguments to the wrapped program.";
    };
    env = mkOption {
      type = with types; attrsOf (submodule (import ./env-type.nix));
      default = { };
      description = "FIXME env";
    };
    extraWrapperFlags = mkOption {
      type = with types; separatedString " ";
      description = ''
        Raw flags passed to makeWrapper.

        See upstream documentation for make-wrapper.sh : https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/setup-hooks/make-wrapper.sh
      '';
      default = "";
      example = "--argv0 foo --set BAR value";
    };
    pathAdd = mkOption {
      type = with types; listOf package;
      description = ''
        Packages to append to PATH.
      '';
      default = [ ];
      example = lib.literalExpression "[ pkgs.starship ]";
    };
  };

  config = {
    wrapFlags =
      (flatten (
        map (f: [
          "--add-flag"
          f
        ]) config.prependFlags
      ))
      ++ (flatten (
        map (f: [
          "--append-flag"
          f
        ]) config.appendFlags
      ))
      ++ ([
        "--prefix"
        "PATH"
        ":"
        (lib.makeBinPath config.pathAdd)
      ])
      ++ (flatten (map (e: e.asFlags) (attrValues config.env)));
  };
}
