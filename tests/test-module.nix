{pkgs, ...}: {
  wrappers.hello = {
    env.FOO = "foo";
    env.BAR = "bar";
    basePackage = pkgs.hello;
    flags = [
      "-g Greetings"
    ];
  };
}
