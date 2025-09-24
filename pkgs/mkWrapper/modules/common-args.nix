{ lib, ... }:
let
  inherit (lib) mkOption types;
  strLike = with types; coercedTo anything (x: "${x}") str;
in
{
  imports = [ (lib.mkRenamedOptionModule [ "env" ] [ "envVars" ]) ];

  options = {
    prependFlags = mkOption {
      type = types.listOf strLike;
      default = [ ];
      description = "Flags passed before any arguments to the wrapped program.";
      example = lib.literalExpression ''
        [
          "--config-file"
          ./config.toml
        ]
      '';
    };

    appendFlags = mkOption {
      type = types.listOf strLike;
      default = [ ];
      description = "Flags passed after any arguments to the wrapped program. Usually you want to use prependFlags instead.";
      example = lib.literalExpression ''
        [
          "--config-file"
          ./config.toml
        ]
      '';
    };

    pathAdd = mkOption {
      type = with types; listOf package;
      default = [ ];
      description = "Packages to append to PATH.";
      example = lib.literalExpression "[ pkgs.starship ]";
    };

    envVars = mkOption {
      type = types.attrsOf (
        types.submodule (
          { name, ... }:
          {
            options = {
              name = mkOption {
                type = types.str;
                default = name;
                description = "Name of the variable.";
                example = "GIT_CONFIG";
              };

              value = mkOption {
                type = types.nullOr strLike;
                default = null;
                description = ''
                  Value of the variable to be set.
                  Set to `null` to unset the variable.

                  Note that any environment variable will be escaped. For example, `value = "$HOME"`
                  will be converted to the literal `$HOME`, with its dollar sign.
                '';
                example = lib.literalExpression "./gitconfig";
              };

              force = mkOption {
                type = types.bool;
                default = false;
                description = ''
                  Whether the value should be always set to the specified value.
                  If set to `true`, the program will not inherit the value of the variable
                  if it's already present in the environment.
                '';
                example = true;
              };
            };
          }
        )
      );
      default = { };
      description = "Structured configuration for environment variables.";
      example = lib.literalExpression "{ GIT_CONFIG.value = ./gitconfig; }";
    };

    extraWrapperFlags = mkOption {
      type = types.separatedString " ";
      default = "";
      description = "Raw flags passed to makeWrapper.";
      example = "--argv0 foo --set BAR value";
    };

    wrapperType = mkOption {
      type = types.enum [
        "shell"
        "binary"
      ];
      default = "binary";
      description = "Whether to use a binary or a shell wrapper.";
      example = "shell";
    };
  };
}
