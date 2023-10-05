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



## **Installation**

First, bring wrapper-manager as a flake input:

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

The `lib` output is a function that evaluates the module:

```nix
wrapper-manager.lib {
  inherit pkgs;
  modules = [
    ./my-module.nix
  ];
}
```

As a shorthand for `(wrapper-manager.lib { ... }).config.build.toplevel`, you can use `wrapper-manager.lib.build` instead.


### Standalone application

Wrapper-manager can be evaluated in any context that accepts a package, like in
`environment.systemPackages`, `users.users.my-user.packages`, `home.packages`, etc.


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


## **Configuration examples**

These are some examples of wrapper-manager used in the wild. Feel free to PR yours.

- https://github.com/viperML/dotfiles/tree/master/wrappers


## To-do's

https://github.com/viperML/wrapper-manager/issues

## Changelog

- 2023-10-05
  - Changed wrapper.name.env to be an attrset instead
  - Added the ability to unset a variable with wrapper.name.env.unset
  - Added the ability to disallow overriding a variable with wrapper.name.env.force
  - Changed the way wrapper.name.flags is handled so that every flag is escaped

- 2023-08-12
  - Added wrappers.name.renames option.