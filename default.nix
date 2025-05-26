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
        ./modules
      ] ++ modules;
      specialArgs = {
        inherit pkgs;
      } // specialArgs;
    };
in
{
  v2 = {
    inherit eval;
    __functor = _: eval;
    build = args: (eval args).config.build.toplevel;
  };
}
