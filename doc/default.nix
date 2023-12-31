{
  pkgs,
  optionsCommonMark,
}: let
  inherit (pkgs) lib;
  docStdenv = pkgs.stdenvNoCC;

  HUGO_THEMESDIR = lib.pipe (pkgs.callPackages ./generated.nix {}) [
    builtins.attrValues
    (map (elem:
      elem.src.overrideAttrs (_: {
        name = elem.pname;
      })))
    (pkgs.linkFarmFromDrvs "themes")
  ];
in {
  packages = {
    doc = pkgs.callPackage ({stdenv}:
      stdenv.mkDerivation {
        name = "wrapper-manager-doc";
        src = ./.;
        inherit HUGO_THEMESDIR;
        nativeBuildInputs = [
          pkgs.hugo
        ];

        preBuild = ''
          ln -vsf ${optionsCommonMark} content/docs/module/_index.md
        '';

        buildPhase = ''
          runHook preBuild
          mkdir -p builddir
          hugo --minify --destination builddir
          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall
          cp -vr builddir $out
          runHook postInstall
        '';
      }) {
      stdenv = docStdenv;
    };
  };

  devShells = {
    doc = with pkgs;
      mkShell.override {stdenv = docStdenv;} {
        nativeBuildInputs = [
          hugo
        ];
        inherit HUGO_THEMESDIR;
        shellHook = ''
          echo "Linking the module options. Please refresh the devshell if you make changes"
          ln -vsf ${optionsCommonMark} content/docs/module/_index.md
        '';
      };
  };
}
