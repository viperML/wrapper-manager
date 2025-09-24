{ config, lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  options = {
    overrideAttrs = mkOption {
      type = with types; functionTo attrs;
      default = lib.id;
      defaultText = lib.literalExpression "lib.id";
      description = "Function to override attributes from the final package.";
      example = lib.literalExpression ''
        oldAttrs: {
          pname = "''${oldAttrs.pname}-with-settings";
        }
      '';
    };

    wrapped = mkOption {
      type = types.package;
      readOnly = true;
      apply = x: x.overrideAttrs config.overrideAttrs;
      description = "(Read-only) The final wrapped package.";
    };
  };
}
