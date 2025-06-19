let
  pkgs = import <nixpkgs> { };
  wrapper-manager = import ../.;
  wrap = wrapper-manager.lib.wrapWith pkgs;
in
wrap {
  basePackage = pkgs.hello;
  prependFlags = [
    "-g"
    "Goodbye"
  ];
}
