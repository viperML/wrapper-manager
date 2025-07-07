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

<p class="wm-logo" align="center" style="margin: 2em auto;">
  <img src="./public/wrapper.svg" alt="wrapped nixos logo" onerror="this.remove()"  width="350"/>
</p>


```nix
{pkgs, ...}: {
  # Build a custom nushell wrapper
  # that self-bundles its configuration and dependencies
  # ~/.config/nushell is not neeeded!
  wrappers.nushell = {
    basePackage = pkgs.nushell;
    prependFlags = [
      "--env-config"
      ./env.nu
      "--config"
      ./config.nu
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


## **Documentation**

https://viperml.github.io/wrapper-manager


## **Installation and usage**

Wrapper-manager is a library for creating wrappers. What you do with the wrappers is up to you,
you can use them to be installed with `nix-env -i`, add them to your NixOS config, to a devshell,
etc.

```nix
let
  # Evaluate the module system

  wm-eval = wrapper-manager.lib {
    inherit pkgs;
    modules = [
      ./other-module.nix
      {
        wrappers.hello = {
          basePackage = pkgs.hello;
          prependFlags = ["-g" "Hi"];
        };
      }
    ];
  };

  # Extract one of the wrapped packages
  myHello = wm-eval.config.wrappers.hello.wrapped;
  #=>       «derivation /nix/store/...»

  # Extract all wrapped packages
  allWrappers = wm-eval.config.build.packages;
  #=>           { hello = «derivation /nix/store/...»; }

  # Add all the wrappers to systemPackages:
  environment.systemPackages = [ ] ++ (builtins.attrValues wm-eval.config.build.packages);
  # or using the bundle:
  environment.systemPackages = [ wm-eval.config.build.toplevel ];


  # Wrap a singular package
  myGit = wrapper-manager.lib.wrapWith pkgs {
    basePackage = pkgs.git;
    env.GIT_CONFIG.value = ./gitconfig;
  };
  #=> «derivation /nix/store/...»
in
  ...
```

### How do I get `wrapper-manager.lib` ?

The main entrypoint is `wrapper-manager.lib`. To get it:

### Flakes

```nix
{
  inputs.wrapper-manager.url = "github:viperML/wrapper-manager";

  outputs = {self, wrapper-manager}: let
    # wrapper-manager.lib { ... }
  in {};
}
```

### Npins

```
$ npins add github viperML wrapper-manager
```

```nix
let
  sources = import ./npins;
  wrapper-manager = import sources.wrapper-manager;

  # wrapper-manager.lib { ... }
in
  ...
```


## **Configuration examples**

These are some examples of wrapper-manager used in the wild. Feel free to PR yours.

- https://github.com/viperML/dotfiles/tree/master/modules/wrapper-manager


## To-do's

https://github.com/viperML/wrapper-manager/issues

## Changelog

- 2025-06-19
  - Full rewrite
  - `flags` has been removed in favor of `prependFlags`

- 2024-08-24
  - Added `postBuild` option

- 2024-08-14
  - Added `overrideAttrs` option

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

<style>
  .VPDoc .wm-logo {
    display: none;
  }
</style>
