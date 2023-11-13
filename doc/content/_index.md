####

<h1>
    <p align="center">
        <b>wrapper-manager</b>
    </p>
</h1>

<h3>
    <p align="center">
        <i>Post-modern configuration management</i>
    </p>
</h3>

<p align="center" style="margin: 2em auto;">
  <img src="./doc/static/wrapper.svg" alt="wrapped nixos logo" onerror="this.remove()"  width="350"/>
</p>


```nix
{pkgs, ...}: {
  # Build a custom nushell wrapper
  # that self-bundles its configuration and dependencies
  # ~/.config/nushell is not neeeded!
  wrappers.nushell = {
    basePackage = pkgs.nushell;
    flags = [
      "--env-config" ./env.nu
      "--config" ./config.nu
    ];
    env.STARSHIP_CONFIG.value = ../starship.toml;
    pathAdd = [
      pkgs.starship
      pkgs.carapace
    ];
  };
}
```

Result (nushell executable):

```bash
#! /nix/store/51sszqz1d9kpx480scb1vllc00kxlx79-bash-5.2-p15/bin/bash -e
export STARSHIP_CONFIG=${STARSHIP_CONFIG-'/nix/store/9gyqz7x765dgh6jvjgnsmiq1zp8lm2y8-starship.toml'}
PATH=${PATH:+':'$PATH':'}
PATH=${PATH/':''/nix/store/11hrc3lnzp8jyb3afmmy9h4m4c30jkgs-starship-1.15.0/bin'':'/':'}
PATH='/nix/store/11hrc3lnzp8jyb3afmmy9h4m4c30jkgs-starship-1.15.0/bin'$PATH
PATH=${PATH#':'}
PATH=${PATH%':'}
export PATH
PATH=${PATH:+':'$PATH':'}
PATH=${PATH/':''/nix/store/vzvxm72pj68fc0120fw1k67b73iaf6g9-carapace-0.25.1/bin'':'/':'}
PATH='/nix/store/vzvxm72pj68fc0120fw1k67b73iaf6g9-carapace-0.25.1/bin'$PATH
PATH=${PATH#':'}
PATH=${PATH%':'}
export PATH
exec -a "$0" "/nix/store/k57j42qv2p1msgf9djsrzssnixlblw9v-nushell-0.82.0/bin/.nu-wrapped"  --env-config /nix/store/zx7cc0fmr3gsbxfvdri8b1pnybsh8hd9-env.nu --config /nix/store/n4mdvfbcc81i9bhrakw7r6wnk4nygbdl-config.nu "$@"
```

---

Wrapper-manager is a Nix library that allows you to configure your favorite applications
without adding files into ~/.config.
This is done by creating wrapper scripts that set the appropriate environment variables, like PATH,
or pass extra flags to the wrapped program.

Nix offers very good reliability and reproducibility thanks to its read-only store.
However, putting symlinks to it in your $HOME starts breaking this property.
Because any program can tamper files in ~, the stability of your system is a bit
more fragile.

Wrapper-manager leverages the nixpkgs' functions `wrapProgram` and `symlinkJoin` to create wrappers
around your applications, providing an easy-to use interface, and also getting
around some of their shortcomings.


## **Module documentation**

https://viperml.github.io/wrapper-manager/docs/module


## **Installation/usage**

First, you need to instantiate wrapper-manager's lib. This can be done by pulling the WM flake, or by pulling the repo tarball directly.

### Flake

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "...";

    # Add the wrapper-manager flake
    wrapper-manager = {
      url = "github:viperML/wrapper-manager";
      # WM's nixpkgs is only used for tests, you can safely drop this if needed.
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {self, nixpkgs, wrapper-manager}: { ... };
}
```

### Classic

Wrapper-manager can be pulled in a classic (non-flake) setup for a devshell or nixos configuration, like so:

```nix
# shell.nix , or configuration.nix

# or {pkgs, config, ...}: if you are in NixOS...
let
  pkgs = import <nixpkgs> {};

  # optionally, pin a commit instead of using master
  wrapper-manager = import (builtins.fetchTarball "https://github.com/viperML/wrapper-manager/archive/refs/heads/master.tar.gz") {
    inherit (pkgs) lib;
  };
in
  ...
```

### Evaluating

Now that you already have `wrapper-manager` in scope, you need to evaluate `wrapper-manager.lib`. The argument is an attrset with following elements:

- `pkgs`: your nixpkgs instance used to bring `symlinkJoin` and `makeWrapper`, as well as passing it through the modules for convenience.
- `modules`: a list of wrapper-manager modules. As with NixOS, a module can be passed as a path to a module or directly. A proper module is either an attset, or a function to attrset.
- `specialArgs` (optional): extra arguments passed to the module system.

A convenience shorthand for `(wrapper-manager.lib {...}).config.build.toplevel` is available through: `wrapper-manager.lib.build {}`, which is probably what you want in 99% of the cases.

```nix
# This expression outputs a package, which collects all wrappers.
# You can add it to:
# - environment.systemPackages
# - home.packages
# - mkShell { packages = [...]; }
# - etc

(wrapper-manager.lib.build {
  inherit pkgs;
  modules = [
    ./my-module.nix
    {
      wrappers.foo = { ... };
    }
  ];
})
# => «derivation /nix/store/...»
```

For example, if you want to use wrapper-manager in the context of a devshell, you can instatiate it directly like so:
```nix
# pkgs and wrapper-manager in scope, see previous steps
# ...
mkShell {
  packages = [

    (wrapper-manager.lib.build {
      inherit pkgs;
      modules = [{
        wrappers.stack = {
          basePackage = pkgs.stack;
          flags = [
            "--resolver"
            "lts"
          ];
          env.NO_COLOR.value = "1";
        };
      }];
    })

  ];
}
```


## **Configuration examples**

These are some examples of wrapper-manager used in the wild. Feel free to PR yours.

- https://github.com/viperML/dotfiles/tree/master/wrappers


## To-do's

https://github.com/viperML/wrapper-manager/issues

## Changelog

- 2023-11-13
  - Added `prependFlags`, which maps to `--add-flags`
  - Added `appendFlags`, which maps to `--append-flags`
  - `flags` is now an alias to `prependFlags`, which uses `--add-flags` instead of `--append-flags`

- 2023-11-06
  - Users can now pass their own `specialArgs`

- 2023-10-05
  - Changed wrapper.name.env to be an attrset instead
  - Added the ability to unset a variable with wrapper.name.env.unset
  - Added the ability to disallow overriding a variable with wrapper.name.env.force
  - Changed the way wrapper.name.flags is handled so that every flag is escaped

- 2023-08-12
  - Added wrappers.name.renames option.