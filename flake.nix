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

        doc =
          with pkgs;
          buildNpmPackage {
            name = "doc";
            src = ./doc;
            npmDeps = importNpmLock {
              npmRoot = ./doc;
            };

            inherit (importNpmLock) npmConfigHook;
            env.WRAPPER_MANAGER_OPTIONS_JSON = self.packages.${pkgs.system}.optionsJSON;

            # VitePress hangs if you don't pipe the output into a file
            buildPhase = ''
              runHook preBuild

                local exit_status=0
                npm run build -- --base=/wrapper-manager/ > build.log 2>&1 || {
                    exit_status=$?
                    :
                }
                cat build.log
                return $exit_status

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
