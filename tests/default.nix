let
  pkgs = import <nixpkgs> { };
  wrapper-manager = import ../.;
in
wrapper-manager.v2 {
  inherit pkgs;
  modules = [
    {
      wrappers.hello = {
        basePackage = pkgs.hello;

        programsInheritParent = true; # default false

        appendFlags = [
          "--foo"
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
        };
      };
    }
  ];
}
