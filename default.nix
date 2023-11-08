{lib}: let
  eval = {
    pkgs,
    modules ? [],
  }:
    lib.evalModules {
      modules =
        [
          ./modules
          {
            _module.args.pkgs = pkgs;
          }
        ]
        ++ modules;
      specialArgs = {};
    };
in {
  lib = {
    inherit eval;
    __functor = _: eval;
    build = args: (eval args).config.build.toplevel;
  };
}
