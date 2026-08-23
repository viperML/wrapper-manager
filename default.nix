{
  lib = {
    __functor = self: self.eval;
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
        ]
        ++ modules;
        specialArgs = {
          inherit pkgs;
        }
        // specialArgs;
      };
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
