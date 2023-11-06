{lib}: let
  eval = {
    modules ? [],
    moduleArgs ? {},
  }:
    lib.evalModules {
      modules =
        [
          ./modules
        ]
        ++ modules;
      specialArgs = moduleArgs;
    };
in {
  __functor = _: eval;

  build = args: (eval args).config.build.toplevel;
}
