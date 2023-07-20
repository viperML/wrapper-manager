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

    wrapperConfigurations = forAllSystems (pkgs:
      self.lib {
        inherit pkgs;
      });

    packages = forAllSystems (
      pkgs:
        pkgs.nixosOptionsDoc (let
          toplevel = self.wrapperConfigurations.${pkgs.system};
        in {
          inherit (toplevel) options;
        })
    );
  };
}
