{
  config,
  lib,
  name,
  ...
}: let
  inherit (lib) mkOption types;
in {
  options = {
    name = mkOption {
      type = types.str;
      description = ''
        Name of the variable.
      '';
      default = name;
    };

    value = mkOption {
      type = let
        inherit (types) coercedTo anything str nullOr;
        strLike = coercedTo anything (x: "${x}") str;
      in
        nullOr strLike;
      description = ''
        Value of the variable to be set.
        Set to `null` to unset the variable.

        Note that any environment variable will be escaped. For example, `value = "$HOME"`
        will be converted to the literal `$HOME`, with its dollar sign.
      '';
    };

    force = mkOption {
      type = types.bool;
      description = ''
        Whether the value should be always set to the specified value.
        If set to `true`, the program will not inherit the value of the variable
        if it's already present in the environment.

        Setting it to false when unsetting a variable (value = null)
        will make the option have no effect.
      '';
      default = config.value == null;
      defaultText = lib.literalMD "true if `value` is null, otherwise false";
    };
  };
}
