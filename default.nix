let
  eval =
    {
      pkgs,
      lib ? pkgs.lib,
      modules ? [ ],
      specialArgs ? { },
    }:
    lib.evalModules {
      modules = [
        ./modules/many-wrappers.nix
      ] ++ modules;
      specialArgs = {
        inherit pkgs;
      } // specialArgs;
    };

  doWarn = false;
  maybeWarn = x: if doWarn then builtins.warn (import ./migration.nix) x else x;
in
maybeWarn {
  lib = {
    inherit eval;
    __functor = _: eval;
    wrapWith =
      pkgs: module:
      (pkgs.lib.evalModules {
        modules = [
          ./modules/wrapper.nix
          module
        ];
        specialArgs = {
          inherit pkgs;
        };
      }).config.wrapped;
  };
}
