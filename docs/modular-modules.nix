# https://github.com/NixOS/nixpkgs/blob/52c032768a8bd0c7a23fdad4232e50a2962079c2/nixos/modules/misc/documentation/modular-services.nix
{ lib, pkgs, ... }:
let
  fakeSubmodule =
    module:
    lib.mkOption {
      type = lib.types.submodule [
        module
        {
          _file = ../modules;
          options.wrappers =
            lib.mapAttrs
              (
                name: _:
                lib.mkOption {
                  type = lib.types.submodule ../modules/wrapper.nix;
                  description = "Wrapper created by option `${name}`.";
                }
              )
              (lib.evalModules {
                modules = [
                  module
                  {
                    options.wrappers = lib.mkOption {
                      type = lib.types.attrsOf (lib.types.submodule ../modules/wrapper.nix);
                    };
                  }
                ];
              }).config.wrappers;
        }
      ];
      description = "This is a modular module (inspired by [modular service](https://nixos.org/manual/nixos/unstable/#modular-services)), which can be imported into a wrapper-manager configuration using the `wrappers` option.";
    };

  modularModulesModule = {
    _file = "${__curPos.file}#L${toString __curPos.line}";
    options = { };
  };
in
modularModulesModule
