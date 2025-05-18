{
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkOption
    types
    ;

  envToWrapperArg =
    _:
    {
      name,
      force,
      value,
    }:
    let
      unsetArg =
        if !force then
          (lib.warn ''
            ${
              lib.showOption [
                "env"
                name
                "value"
              ]
            } is null (indicating unsetting the variable), but ${
              lib.showOption [
                "env"
                name
                "force"
              ]
            } is false. This option will have no effect
          '' [ ])
        else
          [
            "--unset"
            name
          ];
      setArg =
        let
          arg = if force then "--set" else "--set-default";
        in
        [
          arg
          name
          value
        ];
    in
    if value == null then unsetArg else setArg;

  wrapperOpts =
    { config, ... }:
    {
      imports = [
        (lib.mkAliasOptionModuleMD [ "flags" ] [ "prependFlags" ])
      ];

      options = {
        basePackage = mkOption {
          type = with types; package;
          description = ''
            Program to be wrapped.
          '';
          example = lib.literalExpression "pkgs.nix";
        };

        extraPackages = mkOption {
          type = with types; listOf package;
          description = ''
            Extra packages to also wrap.
          '';
          example = lib.literalExpression "[ pkgs.git-extras pkgs.delta ]";
          default = [ ];
        };

        env = mkOption {
          # This is a hack to display a helpful error message to the user about the changed api.
          # Should be changed to just `attrsOf submodule` at some point.
          type =
            let
              inherit (lib) any isStringLike showOption;
              actualType = types.submodule ./env-type.nix;
              forgedType = actualType // {
                # There's special handling if this value is present which makes merging treat this type as any other submodule type,
                # so we lie about there being no sub-modules so that our `check` and `merge` get called.
                getSubModules = null;
                check = v: isStringLike v || actualType.check v;
                merge =
                  loc: defs:
                  if any (def: isStringLike def.value) defs then
                    throw ''
                      ${showOption loc} has been changed to an attribute set.
                      Instead of assigning value directly, use ${showOption (loc ++ [ "value" ])} = <value>;
                    ''
                  else
                    (actualType.merge loc defs);
              };
            in
            types.attrsOf forgedType;
          description = ''
            Structured environment variables.
          '';
          default = { };
          example = {
            NIX_CONFIG.value = "allow-import-from-derivation = false";
          };
        };

        prependFlags = mkOption {
          type = with types; listOf (coercedTo anything (x: "${x}") str);
          description = ''
            Prepend a flag to the invocation of the program, **before** any arguments passed to the wrapped executable.
          '';
          default = [ ];
          example = lib.literalExpression ''
            [
              "--config" ./config.sh
              "--ascii" ./ascii
            ]
          '';
        };

        appendFlags = mkOption {
          type = with types; listOf (coercedTo anything (x: "${x}") str);
          description = ''
            Append a flag to the invocation of the program, **after** any arguments passed to the wrapped executable.
          '';
          default = [ ];
          example = lib.literalExpression ''
            [
              "--config" ./config.sh
              "--ascii" ./ascii
            ]
          '';
        };

        pathAdd = mkOption {
          type = with types; listOf package;
          description = ''
            Packages to append to PATH.
          '';
          default = [ ];
          example = lib.literalExpression "[ pkgs.starship ]";
        };

        extraWrapperFlags = mkOption {
          type = with types; separatedString " ";
          description = ''
            Raw flags passed to makeWrapper.

            See upstream documentation for make-wrapper.sh : https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/setup-hooks/make-wrapper.sh
          '';
          default = "";
          example = "--argv0 foo --set BAR value";
        };

        wrapped = mkOption {
          type = with types; package;
          readOnly = true;
          description = ''
            (Output) Final wrapped package.
          '';
        };

        renames = mkOption {
          type = with types; attrsOf str;
          description = ''
            Map of renames FROM = TO. Renames every binary /bin/FROM to /bin/TO, adjusting other
            necessary files.
          '';
          default = { };
          example = {
            "nvim" = "custom-nvim";
          };
        };

        overrideAttrs = mkOption {
          type = with types; functionTo attrs;
          description = ''
            Function to override attributes from the final package.
          '';
          default = lib.id;
          example = ''
            old: {
              pname = "''${old.pname}-wrapped";
            }
          '';
        };

        postBuild = mkOption {
          type = with types; str;
          description = ''
            Extra fragment of bash to be run after the main wrapper-manager code.
          '';
          default = "";
          example = ''
            $out/bin/nvim -l ''${./check.lua}
          '';
        };
      };

      config = {
        wrapped =
          let
            mkWrapper =
              basePackage:
              let
                hasMan = builtins.any (builtins.hasAttr "man") ([ basePackage ] ++ config.extraPackages);
              in
              (
                (
                  (pkgs.symlinkJoin {
                    inherit (basePackage) name;
                    paths = [ basePackage ] ++ config.extraPackages;
                    nativeBuildInputs = [ pkgs.makeWrapper ];
                    postBuild =
                      let
                        envArgs = lib.mapAttrsToList envToWrapperArg config.env;
                        # Yes, the arguments are escaped later, yes, this is intended to "double escape",
                        # so that they are escaped for wrapProgram and for the final binary too.
                        prependFlagArgs = map (args: [
                          "--add-flags"
                          (lib.escapeShellArg args)
                        ]) config.prependFlags;
                        appendFlagArgs = map (args: [
                          "--append-flags"
                          (lib.escapeShellArg args)
                        ]) config.appendFlags;
                        pathArgs = map (p: [
                          "--prefix"
                          "PATH"
                          ":"
                          "${p}/bin"
                        ]) config.pathAdd;
                        allArgs = lib.flatten (envArgs ++ prependFlagArgs ++ appendFlagArgs ++ pathArgs);
                      in
                      ''
                        for file in $out/bin/*; do
                          echo "Wrapping $file"
                          wrapProgram \
                            $file \
                            ${lib.escapeShellArgs allArgs} \
                            ${config.extraWrapperFlags}
                        done

                        # Some derivations have nested symlinks here
                        if [[ -d $out/share/applications && ! -w $out/share/applications ]]; then
                          echo "Detected nested symlink, fixing"
                          temp=$(mktemp -d)
                          cp -v $out/share/applications/* $temp
                          rm -vf $out/share/applications
                          mkdir -pv $out/share/applications
                          cp -v $temp/* $out/share/applications
                        fi

                        cd $out/bin
                        for exe in *; do

                          if false; then
                            exit 2
                          ${lib.concatStringsSep "\n" (
                            lib.mapAttrsToList (name: value: ''
                              elif [[ $exe == ${lib.escapeShellArg name} ]]; then
                                newexe=${lib.escapeShellArg value}
                                mv -vf $exe $newexe
                            '') config.renames
                          )}
                          else
                            newexe=$exe
                          fi

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
                        done

                        ${lib.optionalString hasMan ''
                          mkdir -p ''${!outputMan}
                          ${lib.concatMapStringsSep "\n" (
                            # p: if lib.hasAttr "man" p then "${pkgs.xorg.lndir}/bin/lndir -silent ${p.man} $out" else "#"
                            p:
                            if p ? "man" then
                              "${lib.getExe pkgs.xorg.lndir} -silent ${p.man} \${!outputMan}"
                            else
                              "echo \"No man output for ${lib.getName p}\""
                          ) ([ basePackage ] ++ config.extraPackages)}
                        ''}

                        ${config.postBuild}
                      '';
                    passthru = (basePackage.passthru or { }) // {
                      unwrapped = basePackage;
                    };
                    outputs = [
                      "out"
                    ] ++ (lib.optional hasMan "man");
                    meta = basePackage.meta // {
                      outputsToInstall = [
                        "out"
                      ] ++ (lib.optional hasMan "man");
                    };
                  })
                  // {
                    override = newAttrs: mkWrapper (basePackage.override newAttrs);
                  }
                )
              );
          in
          mkWrapper config.basePackage;
      };
    };
in
{
  options = {
    wrappers = mkOption {
      type = with types; attrsOf (submodule wrapperOpts);
      default = { };
      description = ''
        Wrapper configuration. See the suboptions for configuration.
      '';
    };
  };

  config = {
  };
}
