{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    forAllSystems = function:
      nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
      ] (system: function nixpkgs.legacyPackages.${system});
  in {
    lib = import ./lib.nix {
      inherit (nixpkgs) lib;
    };

    formatter = forAllSystems (pkgs: pkgs.alejandra);

    wrapperConfigurations = forAllSystems (pkgs: {
      test = self.lib {
        inherit pkgs;
        modules = [./tests/test-module.nix];
      };
    });

    packages = forAllSystems (pkgs: {
      test = self.lib.build {
        inherit pkgs;
        modules = [./tests/test-module.nix];
      };
    });

    legacyPackages = forAllSystems (
      pkgs:
        pkgs.nixosOptionsDoc {
          options =
            (self.lib {
              inherit pkgs;
            })
            .options;
        }
    );
  };
}
