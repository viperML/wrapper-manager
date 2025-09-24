{ mkWrapper }:

{ config, ... }:
{
  imports = [ ./args.nix ];

  wrapped = mkWrapper {
    inherit (config)
      basePackage
      extraPackages
      programs
      prependFlags
      appendFlags
      pathAdd
      envVars
      extraWrapperFlags
      wrapperType
      postBuild
      ;
  };
}
