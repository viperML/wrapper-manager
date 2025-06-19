with import <nixpkgs> { };
let
  pkg = callPackage ./package.nix { };
in
mkShell {
  packages = [
    nodejs
  ];
  env.WRAPPER_MANAGER_OPTIONS_JSON = pkg.options_json;
}
