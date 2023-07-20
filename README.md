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

TODO: wrapper-manager outputs a build-env


## Installation

TODO


## Module documentation

TODO