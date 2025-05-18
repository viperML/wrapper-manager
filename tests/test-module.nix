{
  pkgs,
  lib,
  some-special-arg,
  config,
  ...
}:
{
  wrappers.hello = {
    env.FOO.value = "foo";
    env.BAR.value = "bar";
    basePackage = pkgs.hello;
    flags = [
      "-g"
      some-special-arg
    ];
  };

  wrappers.neofetch = {
    basePackage = pkgs.neofetch.override { x11Support = false; };
    flags = [
      "--ascii_distro"
      "guix"
    ];
    renames = {
      "neofetch" = "neofetch2";
    };
  };

  wrappers.git = {
    basePackage = pkgs.git;
    extraPackages = [ pkgs.git-extras ];
    env.GIT_CONFIG_GLOBAL.value = pkgs.writeText "gitconfig" (lib.fileContents ./gitconfig);
  };

  wrappers.nushell = {
    basePackage = pkgs.nushell;
    pathAdd = [ pkgs.starship ];
  };

  wrappers.wezterm = {
    basePackage = pkgs.wezterm;
    renames = {
      "wezterm" = "wezterm2";
    };
  };

  wrappers.neovim = {
    basePackage = pkgs.neovim;
    renames = {
      "nvim" = "nvim2";
    };
  };

  wrappers.discord = {
    basePackage = pkgs.discord;
    flags = [
      "--disable-gpu"
    ];
  };

  wrappers.hello-wrapped = {
    basePackage = pkgs.hello;
    overrideAttrs = old: {
      name = "hello-wrapped";
      pname = "hello-wrapped-bad";
    };
  };

  wrappers.git-minimal-custom = {
    basePackage = config.wrappers.git.wrapped.override {
      # Same as gitMinimal
      withManual = false;
      osxkeychainSupport = false;
      pythonSupport = false;
      perlSupport = false;
      withpcre2 = false;
    };
  };

  # Test for meta.outputsToInstall
  wrappers.pkg-config = {
    basePackage = pkgs.pkg-config;
  };
}
