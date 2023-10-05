{
  config,
  lib,
  name,
  ...
}: let
  inherit (lib) mkOption types mdDoc;
in {
  options = {
    name = mkOption {
      type = types.str;
      description = mdDoc ''
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
      description = mdDoc ''
        Value of the variable to be set.
        Set to `null` to unset the variable.
      '';
    };

    force = mkOption {
      type = types.bool;
      description = mdDoc ''
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
