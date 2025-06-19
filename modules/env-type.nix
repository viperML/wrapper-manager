{
  config,
  lib,
  name,
  ...
}:
let
  inherit (lib) mkOption types;
in
{
  options = {
    name = mkOption {
      type = types.str;
      description = ''
        Name of the variable.
      '';
      default = name;
      example = "GIT_CONFIG";
    };

    value = mkOption {
      type =
        let
          inherit (types)
            coercedTo
            anything
            str
            nullOr
            ;
          strLike = coercedTo anything (x: "${x}") str;
        in
        nullOr strLike;
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
      description = ''
        Whether the value should be always set to the specified value.
        If set to `true`, the program will not inherit the value of the variable
        if it's already present in the environment.

        Setting it to false when unsetting a variable (value = null)
        will make the option have no effect.
      '';
      default = config.value == null;
      defaultText = lib.literalMD "true if `value` is null, otherwise false";
      example = true;
    };

    asFlags = mkOption {
      type = with types; listOf str;
      internal = true;
      readOnly = true;
    };
  };

  config = {
    asFlags =
      let
        unsetArgs =
          if !config.force then
            (lib.warn ''
              ${
                lib.showOption [
                  "env"
                  config.name
                  "value"
                ]
              } is null (indicating unsetting the variable), but ${
                lib.showOption [
                  "env"
                  config.name
                  "force"
                ]
              } is false. This option will have no effect
            '' [ ])
          else
            [
              "--unset"
              config.name
            ];
        setArgs = [
          (if config.force then "--set" else "--set-default")
          config.name
          config.value
        ];
      in
      (if config.value == null then unsetArgs else setArgs);
  };
}
