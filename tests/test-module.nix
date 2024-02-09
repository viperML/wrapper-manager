{
  pkgs,
  lib,
  some-special-arg,
  ...
}: {
  wrappers.hello = {
    env.FOO.value = "foo";
    env.BAR.value = "bar";
    basePackage = pkgs.hello;
    appendFlags = [
      "-g"
      some-special-arg
    ];
  };

  wrappers.neofetch = {
    basePackage = pkgs.neofetch.override {x11Support = false;};
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
    extraPackages = [pkgs.git-extras];
    env.GIT_CONFIG_GLOBAL.value = pkgs.writeText "gitconfig" (lib.fileContents ./gitconfig);
  };

  wrappers.nushell = {
    basePackage = pkgs.nushell;
    pathAdd = [pkgs.starship];
  };

  wrappers.wezterm = {
    basePackage = pkgs.wezterm;
    renames = {
      "wezterm" = "wezterm2";
    };
  };

  wrappers.neovim = {
    basePackage = pkgs.neovim;
    programs.nvim = {
      target = "nvim2";
    };
  };

  wrappers.discord = {
    basePackage = pkgs.discord;
    programs.discord.prependFlags = [
      "--disable-gpu"
    ];
  };
}
