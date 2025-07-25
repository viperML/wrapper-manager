let
  pkgs = import <nixpkgs> {
    config.allowUnfree = true;
  };
  inherit (pkgs) lib;
  wrapper-manager = import ../.;
in
wrapper-manager.lib {
  inherit pkgs;
  modules = [
    {
      _file = ./multi.nix;
      wrapperType = "shell";

      wrappers.discord = {
        basePackage = pkgs.discord;

        env.NIXOS_OZONE_WL.value = "1";
        prependFlags = [
          "--disable-gpu"
        ];
      };

      wrappers.hello = {
        basePackage = pkgs.hello;
        postBuild = "echo goodbye";
        overrideAttrs = old: {
          pname = "goodbye";
        };
        programs.hello = {
          appendFlags = [
            "-g"
            "Goodbye World"
          ];
        };
      };

      wrappers.zellij = {
        # Checks for __intentionallyOverridingVersion
        basePackage = pkgs.zellij;
      };

      wrappers.hello-bad = {
        basePackage = pkgs.hello;
        flags = [
          "-g"
          "g"
        ];
      };

      wrappers.neofetch = {
        basePackage = pkgs.neofetch.override { x11Support = false; };
        programs.guixfetch = {
          target = "neofetch";
          prependFlags = [
            "--ascii_distro"
            "guix"
          ];
        };
      };

      wrappers.git = {
        basePackage = pkgs.git;
        env.FOO.value = "BAR";
        programs.scalar = { };
      };

      wrappers.fish = {
        basePackage = pkgs.fish;
        programs.fish = {
          wrapFlags = [
            "--prefix"
            "XDG_DATA_DIRS"
            ":"
            (lib.makeSearchPathOutput "out" "share" [
            ])
          ];
        };
      };
    }
  ];
}
