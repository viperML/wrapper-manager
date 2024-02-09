{
  config,
  lib,
  name,
  defaults,
  ...
}: let
  inherit (lib) mkOption types mdDoc literalMD;
in {
  options = {
    name = mkOption {
      type = types.str;
      description = mdDoc ''
        Name of the program.
      '';
      default = name;
    };

    target = mkOption {
      type = types.str;
      description = mdDoc ''
        The final name of the program after wrapping.
      '';
      default = config.name;
      defaultText = literalMD "value of name";
    };
  };

  config = {
    inherit
      (defaults)
      env
      prependFlags
      appendFlags
      pathAdd
      extraWrapperFlags
      ;
  };
}
