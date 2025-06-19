let
  pkgs = import <nixpkgs> { };
  wrapper-manager = import ../.;
  wrap = wrapper-manager.v2.wrapWith pkgs;
in
wrap {
  basePackage = pkgs.hello;
  prependFlags = [
    "-g"
    "Goodbye"
  ];
}
