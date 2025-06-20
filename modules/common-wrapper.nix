{
  lib,
  config,
  options,
  ...
}:
let
  inherit (lib) mkOption types flatten;
  inherit (builtins) attrValues;
  flagsType = with types; listOf (coercedTo anything (x: "${x}") str);
in
{
  options = {
    wrapFlags = mkOption {
      type = flagsType;
      default = [ ];
      description = "Structured flags passed to makeWrapper.";
      example = [
        "--argv0"
        "myprog"
      ];
    };
    appendFlags = mkOption {
      type = flagsType;
      default = [ ];
      description = "Flags passed after any arguments to the wrapped program. Usually you want to use prependFlags instead.";
      example = lib.literalExpression ''
        ["--config-file" ./config.toml]
      '';
    };
    # Poor's man mkRemovedOptionModule
    # As we don't have assertions
    flags = mkOption {
      type = flagsType;
      default = [ ];
      description = "(Deprecated) Flags passed before any arguments to the wrapped program. Use prependFlags instead";
      apply =
        flags:
        if flags == [ ] then
          [ ]
        else
          throw "The option `${lib.showOption [ "flags" ]}' used in ${lib.showFiles options.flags.files} is deprecated. Use `${
            lib.showOption [ "prependFlags" ]
          }' instead.";
    };
    prependFlags = mkOption {
      type = flagsType;
      default = [ ];
      description = "Flags passed before any arguments to the wrapped program.";
      example = lib.literalExpression ''
        ["--config-file" ./config.toml]
      '';
    };
    env = mkOption {
      type = with types; attrsOf (submodule ./env-type.nix);
      default = { };
      description = "Structured configuration for environment variables.";
      example = lib.literalExpression ''
        {
          GIT_CONFIG.value = ./gitconfig;
        }
      '';
    };
    extraWrapperFlags = mkOption {
      type = with types; separatedString " ";
      description = ''
        Raw flags passed to makeWrapper. You may want to use wrapFlags instead.
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
    wrapperType = mkOption {
      description = "Whether to use a binary or a shell wrapper.";
      type = types.enum [
        "shell"
        "binary"
      ];
      default = "binary";
      example = "shell";
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
      # Force the eval of config.flags to trigger throw
      ++ (flatten (
        map (f: [
          "--add-flag"
          f
        ]) config.flags
      ))
      ++ (flatten (
        map (f: [
          "--append-flag"
          f
        ]) config.appendFlags
      ))
      ++ (lib.optionals (config.pathAdd != [ ]) [
        "--prefix"
        "PATH"
        ":"
        (lib.makeBinPath config.pathAdd)
      ])
      ++ (flatten (map (e: e.asFlags) (attrValues config.env)));
  };
}
