{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    ndg = {
      url = "github:feel-co/ndg";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
  };

  outputs = {
    self,
    nixpkgs,
    ndg,
  }: let
    forAllSystems = function:
      nixpkgs.lib.genAttrs
      [
        "x86_64-linux"
        "aarch64-linux"
      ]
      (
        system:
          function
          # Import nixpkgs to try google-chrome wrapper
          # this pkgs is not used by the consumer, only .lib
          (
            import nixpkgs {
              inherit system;
              config.allowUnfree = true;
            }
          )
      );
  in
    (import ./default.nix {inherit (nixpkgs) lib;})
    // {
      formatter = forAllSystems (pkgs: pkgs.alejandra);

      checks = forAllSystems (
        pkgs:
          (self.lib {
            inherit pkgs;
            modules = [./tests/test-module.nix];
            specialArgs = {
              some-special-arg = "foo";
            };
          })
          .config
          .build
          .packages
      );

      packages = forAllSystems (
        pkgs: {
          doc = ndg.packages.${pkgs.system}.ndg-builder.override {
            evaluatedModules = self.lib {
              inherit pkgs;
              modules = [];
            };
          };
        }
      );
    };
}
