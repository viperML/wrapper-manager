let
  overlays.default =
    final: prev:
    prev.lib.packagesFromDirectoryRecursive {
      inherit (final) callPackage;
      directory = ./pkgs;
    };

  eval =
    {
      pkgs,
      modules ? [ ],
      specialArgs ? { },
    }:
    pkgs.lib.evalModules {
      modules = [ ./modules ] ++ modules;
      specialArgs = {
        pkgs = pkgs.extend overlays.default;
      }
      // specialArgs;
    };
in
{
  inherit overlays;
  lib = {
    inherit eval;
    __functor = _: eval;
    wrapWith =
      pkgs: module:
      (pkgs.lib.evalModules {
        modules = [
          ./modules/wrapper.nix
          pkgs.mkWrapper.modules.wrapped
          module
        ];
        specialArgs = {
          pkgs = pkgs.extend overlays.default;
        };
      }).config.wrapped;
  };
}
