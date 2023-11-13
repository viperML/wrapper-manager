{
  lib,
  pkgs,
  ...
}: let
  inherit
    (lib)
    mkOption
    types
    ;

  wrapperOpts = {config, ...}: {
    imports = [
      (lib.mkAliasOptionModuleMD ["flags"] ["prependFlags"])
    ];

    options = {
      basePackage = mkOption {
        type = with types; package;
        description = lib.mdDoc ''
          Program to be wrapped.
        '';
        example = lib.literalExpression "pkgs.nix";
      };

      extraPackages = mkOption {
        type = with types; listOf package;
        description = lib.mdDoc ''
          Extra packages to also wrap.
        '';
        example = lib.literalExpression "[ pkgs.git-extras pkgs.delta ]";
        default = [];
      };

      env = mkOption {
        # This is a hack to display a helpful error message to the user about the changed api.
        # Should be changed to just `attrsOf submodule` at some point.
        type = let
          inherit (lib) any isStringLike showOption;
          actualType = types.submodule ./env-type.nix;
          forgedType =
            actualType
            // {
              # There's special handling if this value is present which makes merging treat this type as any other submodule type,
              # so we lie about there being no sub-modules so that our `check` and `merge` get called.
              getSubModules = null;
              check = v: isStringLike v || actualType.check v;
              merge = loc: defs:
                if any (def: isStringLike def.value) defs
                then
                  throw ''
                    ${showOption loc} has been changed to an attribute set.
                    Instead of assigning value directly, use ${showOption (loc ++ ["value"])} = <value>;
                  ''
                else (actualType.merge loc defs);
            };
        in
          types.attrsOf forgedType;
        description = lib.mdDoc ''
          Structured environment variables.
        '';
        default = {};
        example = {
          NIX_CONFIG.value = "allow-import-from-derivation = false";
        };
      };

      prependFlags = mkOption {
        type = with types; listOf (coercedTo anything (x: "${x}") str);
        description = lib.mdDoc ''
          Prepend a flag to the invocation of the program, t**before** any arguments passed to the wrapped executable.
        '';
        default = [];
        example = lib.literalExpression ''
          [
            "--config" ./config.sh
            "--ascii" ./ascii
          ]
        '';
      };

      appendFlags = mkOption {
        type = with types; listOf (coercedTo anything (x: "${x}") str);
        description = lib.mdDoc ''
          Append a flag to the invocation of the program, **after** any arguments passed to the wrapped executable.
        '';
        default = [];
        example = lib.literalExpression ''
          [
            "--config" ./config.sh
            "--ascii" ./ascii
          ]
        '';
      };

      pathAdd = mkOption {
        type = with types; listOf package;
        description = lib.mdDoc ''
          Packages to append to PATH.
        '';
        default = [];
        example = lib.literalExpression "[ pkgs.starship ]";
      };

      extraWrapperFlags = mkOption {
        type = with types; separatedString " ";
        description = lib.mdDoc ''
          Raw flags passed to makeWrapper.

          See upstream documentation for make-wrapper.sh : https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/setup-hooks/make-wrapper.sh
        '';
        default = "";
        example = "--argv0 foo --set BAR value";
      };

      wrapped = mkOption {
        type = with types; package;
        readOnly = true;
        description = lib.mdDoc ''
          (Output) Final wrapped package.
        '';
      };

      renames = mkOption {
        type = with types; attrsOf str;
        description = lib.mdDoc ''
          Map of renames FROM = TO. Renames every binary /bin/FROM to /bin/TO, adjusting other
          necessary files.
        '';
        default = {};
        example = {
          "nvim" = "custom-nvim";
        };
      };
    };

    config = {
      wrapped = let
        envToWrapperArg = name: config: let
          optionStr = attr: lib.showOption ["env" name attr];
          unsetArg =
            if !config.force
            then
              (lib.warn ''
                ${optionStr "value"} is null (indicating unsetting the variable), but ${optionStr "force"} is false. This option will have no effect
              '' [])
            else ["--unset" config.name];
          setArg = let
            arg =
              if config.force
              then "--set"
              else "--set-default";
          in [arg config.name config.value];
        in
          if config.value == null
          then unsetArg
          else setArg;
        result =
          pkgs.symlinkJoin ({
              paths = [config.basePackage] ++ config.extraPackages;
              nativeBuildInputs = [pkgs.makeWrapper];
              postBuild = let
                envArgs = lib.mapAttrsToList envToWrapperArg config.env;
                # Yes, the arguments are escaped later, yes, this is intended to "double escape",
                # so that they are escaped for wrapProgram and for the final binary too.
                prependFlagArgs = map (args: ["--add-flags" (lib.escapeShellArg args)]) config.prependFlags;
                appendFlagArgs = map (args: ["--append-flags" (lib.escapeShellArg args)]) config.appendFlags;
                pathArgs = map (p: ["--prefix" "PATH" ":" "${p}/bin"]) config.pathAdd;
                allArgs = lib.flatten (envArgs ++ prependFlagArgs ++ appendFlagArgs ++ pathArgs);
              in ''
                for file in $out/bin/*; do
                  echo "Wrapping $file"
                  wrapProgram \
                    $file \
                    ${lib.escapeShellArgs allArgs} \
                    ${config.extraWrapperFlags}
                done

                cd $out/bin
                for exe in *; do

                  if false; then
                    exit 2
                  ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: value: ''
                    elif [[ $exe == ${lib.escapeShellArg name} ]]; then
                      newexe=${lib.escapeShellArg value}
                      mv -vf $exe $newexe
                  '')
                  config.renames)}
                  else
                    newexe=$exe
                  fi

                  # Fix .desktop files
                  # This list of fixes might not be exhaustive
                  for file in $out/share/applications/*; do
                    echo "Fixing $file"
                    sed -i "s#/nix/store/.*/bin/$exe #$out/bin/$newexe #" "$file"
                    sed -i -E "s#Exec=$exe([[:space:]])#Exec=$out/bin/$newexe\1#g" "$file"
                    sed -i -E "s#TryExec=$exe([[:space:]]*)#TryExec=$out/bin/$newexe\1#g" "$file"
                  done
                done


                # I don't know of a better way to create a multe-output derivation for symlinkJoin
                # So if the packages have man, just link them into $out
                ${
                  lib.concatMapStringsSep "\n"
                  (p:
                    if lib.hasAttr "man" p
                    then "${pkgs.xorg.lndir}/bin/lndir -silent ${p.man} $out"
                    else "#")
                  ([config.basePackage] ++ config.extraPackages)
                }
              '';
            }
            // lib.getAttrs [
              "name"
              "meta"
            ]
            config.basePackage)
          // (lib.optionalAttrs (lib.hasAttr "pname" config.basePackage) {
            inherit (config.basePackage) pname;
          })
          // (lib.optionalAttrs (lib.hasAttr "version" config.basePackage) {
            inherit (config.basePackage) version;
          });
      in
        lib.recursiveUpdate result {
          meta.outputsToInstall = ["out"];
        };
    };
  };
in {
  options = {
    wrappers = mkOption {
      type = with types; attrsOf (submodule wrapperOpts);
      default = {};
      description = lib.mdDoc ''
        Wrapper configuration. See the suboptions for configuration.
      '';
    };
  };

  config = {
  };
}
