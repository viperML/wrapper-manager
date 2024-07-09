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

  commonOpts = {
    options = {
      env = mkOption {
        type = with types; attrsOf (submodule ./env-type.nix);
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
          Prepend a flag to the invocation of the program, **before** any arguments passed to the wrapped executable.
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
    };
  };

  wrapperOpts = {
    config,
    name,
    ...
  }: {
    imports = [
      commonOpts
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

      wrapByDefault = mkOption {
        type = with types; bool;
        description = lib.mdDoc ''
          Whether to wrap all programs under bin/ by default.
        '';
        example = false;
        default = true;
      };

      programs = mkOption {
        type = with types;
          attrsOf (submoduleWith {
            shorthandOnlyDefinesConfig = true;
            modules = [commonOpts ./program-type.nix];
            specialArgs = {
              defaults = config;
            };
          });
        description = lib.mdDoc ''
          Programs to wrap.
        '';
        example = {
          fish = {
            prependFlags = ["-C" "echo Hello, fish"];
          };
        };
        default = {};
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
      programs = let
        renamesOpt = lib.showOption ["wrappers" name "renames"];
        suggestedOpt = lib.showOption ["wrappers" name "programs" "<name>" "target"];
      in
        lib.warnIf
        (config.renames != {})
        "${renamesOpt} is deprecated. Set ${suggestedOpt} instead"
        (lib.mapAttrs (_: target: {inherit target;}) config.renames);
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
        wrapProgramStr = {
          name,
          target,
          env,
          prependFlags,
          appendFlags,
          pathAdd,
          extraWrapperFlags,
          ...
        }: let
          envArgs = lib.mapAttrsToList envToWrapperArg env;
          # Yes, the arguments are escaped later, yes, this is intended to "double escape",
          # so that they are escaped for wrapProgram and for the final binary too.
          prependFlagArgs = map (args: ["--add-flags" (lib.escapeShellArg args)]) prependFlags;
          appendFlagArgs = map (args: ["--append-flags" (lib.escapeShellArg args)]) appendFlags;
          pathArgs = map (p: ["--prefix" "PATH" ":" "${p}/bin"]) pathAdd;
          allArgs = lib.flatten (envArgs ++ prependFlagArgs ++ appendFlagArgs ++ pathArgs);
          renameStr = lib.optionalString (name != target) ''
            mv -vf ${name} ${lib.escapeShellArg target}
          '';
        in ''
          echo "Wrapping ${name}"
          wrapProgram \
            "$out/bin/${name}" \
            ${lib.escapeShellArgs allArgs} \
            ${extraWrapperFlags}

          ${renameStr}
          exe="${name}"
          newexe="${target}"

          # Fix .desktop files
          # This list of fixes might not be exhaustive
          for file in $out/share/applications/*; do
            echo "Fixing file=$file for exe=$exe"
            set -x
            trap "set +x" ERR
            sed -i "s#/nix/store/.*/bin/$exe #$out/bin/$newexe #" "$file"
            sed -i -E "s#Exec=$exe([[:space:]]*)#Exec=$out/bin/$newexe\1#g" "$file"
            sed -i -E "s#TryExec=$exe([[:space:]]*)#TryExec=$out/bin/$newexe\1#g" "$file"
            set +x
          done
        '';
        defaultWrappers = let
          moveOutPrograms =
            lib.optionalString
            (config.programs != {})
            ''
              echo Moving explicitly wrapped programs
              mv -vf ${lib.escapeShellArgs (lib.mapAttrsToList (_: p: p.name) config.programs)} $wrapped_temp_dir
            '';
          moveBackPrograms =
            lib.optionalString
            (config.programs != {})
            ''
              echo Restoring explicitly wrapped programs
              mv -vf $wrapped_temp_dir/* ./
            '';
        in
          lib.optionalString config.wrapByDefault ''
            wrapped_temp_dir=$(mktemp -d)
            ${moveOutPrograms}
            for file in *; do
              ${wrapProgramStr (config
              // {
                name = "$file";
                target = "$file";
              })}
            done
            ${moveBackPrograms}
          '';
        explicitWrappers =
          lib.concatMapStringsSep
          "\n"
          wrapProgramStr
          (lib.attrValues config.programs);
        result =
          pkgs.symlinkJoin ({
              paths = [config.basePackage] ++ config.extraPackages;
              nativeBuildInputs = [pkgs.makeWrapper];
              postBuild = ''
                # Some derivations have nested symlinks here
                if [[ -d $out/share/applications && ! -w $out/share/applications ]]; then
                  echo "Detected nested symlink, fixing"
                  temp=$(mktemp -d)
                  cp -v $out/share/applications/* $temp
                  rm -vf $out/share/applications
                  mkdir -pv $out/share/applications
                  cp -v $temp/* $out/share/applications
                fi

                pushd $out/bin
                ${defaultWrappers}
                ${explicitWrappers}
                popd

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
              passthru =
                (config.basePackage.passthru or {})
                // {
                  unwrapped = config.basePackage;
                };
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
