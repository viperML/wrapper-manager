{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    {
      self,
      nixpkgs,
    }:
    let
      forAllSystems =
        function:
        nixpkgs.lib.genAttrs
          [
            "x86_64-linux"
            "aarch64-linux"
          ]
          (
            system:
            function (
              import nixpkgs {
                inherit system;
                config.allowUnfree = true;
              }
            )
          );
    in
    (import ./default.nix {
      inherit (nixpkgs) lib;
    })
    // {
      formatter = forAllSystems (pkgs: pkgs.alejandra);

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = [
            pkgs.nodejs
          ];
        };
      });

      packages = forAllSystems (pkgs: {
        optionsJSON =
          (pkgs.nixosOptionsDoc {
            options =
              (self.lib {
                inherit pkgs;
                modules = [ ];
              }).options;
          }).optionsJSON;

        docs =
          with pkgs;
          buildNpmPackage {
            name = "docs";
            src = ./docs;
            npmDeps = importNpmLock {
              npmRoot = ./docs;
            };

            inherit (importNpmLock) npmConfigHook;
            env.WRAPPER_MANAGER_OPTIONS_JSON = self.packages.${pkgs.system}.optionsJSON;

            buildPhase = ''
              runHook preBuild

              # Vitepress hangs when printing normally
              npm run build -- --base=/wrapper-manager/ 2>&1 | cat

              runHook postBuild
            '';

            installPhase = ''
              runHook preInstall

              mv .vitepress/dist $out

              runHook postInstall
            '';
          };
      });

      checks = forAllSystems (
        pkgs:
        (self.lib {
          inherit pkgs;
          modules = [ ./tests/test-module.nix ];
          specialArgs = {
            some-special-arg = "foo";
          };
        }).config.build.packages
      );
    };
}
