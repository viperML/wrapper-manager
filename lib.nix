{lib}: {
  pkgs,
  modules ? [],
}: let
in
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
  }
