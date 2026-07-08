---
title: Cookbook
---

These are some examples of using wrapper-manager to configure applications.

```nix
{ config, pkgs, lib, ... }: {

  # Simple configuration by changing the config dir
  wrappers.kitty = {
    basePackage = pkgs.kitty;
    env.KITTY_CONFIG_DIRECTORY = ./kitty-config;
  };

  # Configure Alacritty using Nix to write the TOML config file
  wrappers.alacritty = let
    alacrittyConfig = {
      font.normal.family = "iosevka";
      terminal.osc52 = "CopyPaste";
    };
  in {
    basePackage = pkgs.alacritty;
    prependFlags = [
      "--config-file"
      ((pkgs.formats.toml { }).generate "alacritty.toml" config.alacrittyConfig)
    ];
  };


  # Enable dark mode and other flags for chrome
  wrappers.chrome = {
    basePackage = pkgs.google-chrome;
    prependFlags = [
      "--force-dark-mode"
      "--enable-features=${
        lib.concatStringsSep "," [
          "WebUIDarkMode"
          "TouchpadOverscrollHistoryNavigation"
          "WaylandTextInputV3"
        ]
      }"
    ];
  };

  # Wezterm configuration using its env var
  wrappers.wezterm = {
    basePackage = pkgs.wezterm;
    env.WEZTERM_CONFIG_FILE = pkgs.writeText "wezterm.lua" ''
      local wezterm = require("wezterm")
      local config = wezterm.config_builder()

      config.font_size = 10

      return config
    '';
  };
  
  # Force an environment variable to a value, and ignored if manually set
  wrappers.git = {
    basePackage = pkgs.git;
    env.GIT_CONFIG = {
      value = ./my-gitconfig;
      force = true;
    };
  };
}
```
