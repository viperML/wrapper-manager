{lib}: let
  eval = {
    pkgs,
    modules ? [],
    specialArgs ? {},
  }:
    lib.evalModules {
      modules =
        [
          ./modules
        ]
        ++ modules;
      specialArgs = {inherit pkgs;} // specialArgs;
    };
in {
  lib = {
    inherit eval;
    __functor = _: eval;
    build = args: (eval args).config.build.toplevel;
  };
}
