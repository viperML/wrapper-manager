# wrapper-manager

This project serves the purpose of managing the dotfiles for your applications
without ever touching your $HOME.

To do this, wrapper-manager wraps your desired applications with their configurations,
such as their are distributed as executables that don't need to read your $HOME/.config.


## Why do I want this instead of home-manager?

Nix offers very good reliability and reproducibility thanks to its read-only store.
However, putting symlinks to it in your $HOME starts breaking this property.

Wrapper-manager keeps everything in the nix store, so you can trust your development
workflow won't break any other day.


## Example

The following tests shows an overview of the available options: [./tests/test-module.nix](./tests/test-module.nix).


## Installation

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

Wrapper-manager can be evaluated in any context: a NixOS configuration, a home-manager one,
or as a package that you `nix shell` or `nix profile install`. The interface is the following:

```nix
wrapper-manager.lib.build {
  inherit pkgs;
  modules = [
    ./my-module.nix
  ];
}
```

This produces a derivation, so feel free to use it on any place, for example:


```nix
users.users.my-user.packages = [
  (wrapper-manager.lib.build {
    inherit pkgs;
    modules = [
      ./my-module.nix
    ];
  })
]
```


## Module documentation

TODO