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
in
{
  lib = builtins.abort "wrapper-manager.lib is deprecated, please upgrade to the .v2 api: https://github.com/viperML/wrapper-manager/pull/26";

  v2 = {
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
