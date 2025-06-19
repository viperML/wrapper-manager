{
  buildNpmPackage,
  importNpmLock,
  nixosOptionsDoc,
  lib,
  pkgs,
}:
let
  options_json =
    (nixosOptionsDoc {
      options =
        ((import ../.).v2 {
          inherit pkgs;
          modules = [ ];
        }).options;
    }).optionsJSON;
in
buildNpmPackage {
  name = "wrapper-manager-docs";
  src = lib.cleanSource ./.;
  npmDeps = importNpmLock {
    npmRoot = lib.cleanSource ./.;
  };

  inherit (importNpmLock) npmConfigHook;

  env.WRAPPER_MANAGER_OPTIONS_JSON = options_json;
  passthru = {inherit options_json;};

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
}
