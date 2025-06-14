let
  pkgs = import <nixpkgs> {
    config.allowUnfree = true;
  };
  wrapper-manager = import ../.;
in
wrapper-manager.v2 {
  inherit pkgs;
  modules = [
    {
      wrappers.discord = {
        basePackage = pkgs.discord;

        env.NIXOS_OZONE_WL.value = "1";
        useBinaryWrapper = false;
      };

      wrappers.hello = {
        basePackage = pkgs.hello;

        programsInheritParent = true; # default false

        appendFlags = [
        ];

        prependFlags = [
          "--bar"
        ];
        pathAdd = [ pkgs.hello ];

        env.FOO.value = "bar";

        programs.hello = {
          # inheritParentConfig = config.wrappers.hello.programsInheritParent;
          # target = "nvim";
          pathAdd = [
            # blah
          ]; # ++ config.wrappers.hello.pathAdd when inheritParentConfig = true

          appendFlags = [
            "-g"
            "Goodbye World"
          ];
        };
      };
    }
  ];
}
