{pkgs, ...}: {
  wrappers.hello = {
    env.FOO = "foo";
    env.BAR = "bar";
    basePackage = pkgs.hello;
    flags = [
      "-g Greetings"
    ];
  };

  wrappers.neofetch = {
    basePackage = pkgs.neofetch.override {x11Support = false;};
    flags = [
      "--ascii_distro guix"
    ];
  };
}
