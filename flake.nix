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
        # "aarch64-linux"
      ] (system:
        function
        # Import nixpkgs to try google-chrome wrapper
        # this pkgs is not used by the consumer, only .lib
        (import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        }));

    doc = forAllSystems (pkgs:
      import ./doc {
        inherit pkgs;
        optionsCommonMark = self.legacyPackages.${pkgs.system}.optionsCommonMark;
      });
  in
    (
      import ./default.nix {
        inherit (nixpkgs) lib;
      }
    )
    // {
      formatter = forAllSystems (pkgs: pkgs.alejandra);

      checks = forAllSystems (pkgs:
        (self.lib {
          inherit pkgs;
          modules = [./tests/test-module.nix];
        })
        .config
        .build
        .packages);

      packages = forAllSystems (pkgs:
        {
        }
        // doc.${pkgs.system}.packages);

      devShells = forAllSystems (pkgs:
        {
        }
        // doc.${pkgs.system}.devShells);

      legacyPackages = forAllSystems (
        pkgs:
          pkgs.nixosOptionsDoc {
            options =
              (self.lib {
                inherit pkgs;
                modules = [
                  {
                    options._module.args = pkgs.lib.mkOption {internal = true;};
                  }
                ];
              })
              .options;
            transformOptions = opt:
              opt
              // {
                declarations = with pkgs.lib;
                  map
                  (decl:
                    if hasPrefix (toString ./.) (toString decl)
                    then let
                      rev = self.rev or "master";
                      subpath = removePrefix "/" (removePrefix (toString ./.) (toString decl));
                    in {
                      url = "https://github.com/viperML/wrapper-manager/blob/${rev}/${subpath}";
                      name = subpath;
                    }
                    else decl)
                  opt.declarations;
              };
          }
      );
    };
}
