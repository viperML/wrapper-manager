# **wrapper-manager**

### *Post-modern configuration management*

```nix
{pkgs, ...}: {
  # Build a custom nushell wrapper
  # that self-bundles its configuration and dependencies
  # ~/.config/nushell is not neeeded!
  wrappers.nushell = {
    basePackage = pkgs.nushell;
    flags = [
      "--env-config ${./env.nu}"
      "--config ${./config.nu}"
    ];
    env.STARSHIP_CONFIG = ../starship.toml;
    pathAdd = [
      pkgs.starship
      pkgs.carapace
    ];
  };
}
```

Result:

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

Wrapper-manager is a Nix library that allows you to configuring your favourite applications
without adding files into ~/.config.
This is done by creating wrapper scripts that set the appropiate environment variables, like PATH;
or pass extra flags to the wrapped program.

Nix offers very good reliability and reproducibility thanks to its read-only store.
However, putting symlinks to it in your $HOME starts breaking this property.
As any program can tamper these symlinks, the stabilty of your sysrtem is a bit
more fragile.

Wrapper-manager solves this problem by directly running your programs from the nix store,
without intermediaries.


## **Documentation**

https://viperml.github.io/wrapper-manager/docs/module



## **Installation**

Add wrapper-manager as a flake-input:

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "...";

    wrapper-manager = {
      url = "github:viperML/wrapper-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {self, nixpkgs, wrapper-manager}: { ... };
}
```

Wrapper-manager can be evaluated in any context: a NixOS configuration, home-manager, flake's package outputs flake's package outputs etc.
The interface is the following:

```nix
wrapper-manager.lib.build {
  inherit pkgs;
  modules = [
    ./my-module.nix
    # or embed the module directly
    {
      wrappers.foo = {
        env.BAR = "bar";
      };
    }
  ];
}
```

### Standalone application

Wrapper-manager can be evaluated in any context that accepts a package, for example:

```nix
# configuration.nix
{config, pkgs, ...}: {
  users.users.my-user.packages = [

    (wrapper-manager.lib.build {
      inherit pkgs;
      modules = [
        ./my-module.nix
      ];
    })

  ];
}
```

### NixOS module

*TODO*


## **Configuration examples**

These are some examples of wrapper-manager used in the wild. Feel free to PR yours.

- https://github.com/viperML/dotfiles/tree/master/wrappers
