{
  lib,
  stdenvNoCC,
  lndir,
  makeWrapper,
  makeBinaryWrapper,
  mkWrapper,
}:
{
  modules.wrapped = lib.modules.importApply ./modules/wrapped.nix { inherit mkWrapper; };
  __functor =
    _:
    lib.extendMkDerivation {
      constructDrv = stdenvNoCC.mkDerivation;
      inheritFunctionArgs = false;
      extendDrvArgs =
        finalAttrs:
        {
          basePackage,
          extraPackages ? [ ],
          programs ? { },
          prependFlags ? [ ],
          appendFlags ? [ ],
          pathAdd ? [ ],
          envVars ? { },
          extraWrapperFlags ? "",
          wrapperType ? "binary",
          postBuild ? "",
          ...
        }:
        let
          printAndRun = cmd: ''
            echo ":: ${cmd}"
            eval "${cmd}"
          '';
          genFlags =
            {
              prependFlags ? [ ],
              appendFlags ? [ ],
              pathAdd ? [ ],
              envVars ? { },
            }:
            lib.concatLists [
              (lib.flatten (
                map (flag: [
                  "--add-flag"
                  flag
                ]) prependFlags
              ))
              (lib.flatten (
                map (flag: [
                  "--append-flag"
                  flag
                ]) appendFlags
              ))
              (lib.optionals (pathAdd != [ ]) [
                "--prefix"
                "PATH"
                ":"
                (lib.makeBinPath pathAdd)
              ])
              (lib.flatten (
                map (env: [
                  (
                    if env.value == null then
                      "--unset"
                    else if env.force then
                      "--set"
                    else
                      "--set-default"
                  )
                  env.name
                  env.value
                ]) (lib.attrValues envVars)
              ))
            ];
          finalArgs =
            (lib.evalModules {
              modules = [
                ./modules/args.nix
                (lib.filterAttrs (
                  name: _:
                  lib.elem name [
                    "basePackage"
                    "extraPackages"
                    "programs"
                    "prependFlags"
                    "appendFlags"
                    "pathAdd"
                    "envVars"
                    "extraWrapperFlags"
                    "wrapperType"
                    "postBuild"
                  ]
                ) finalAttrs)
              ];
            }).config;
          hasMan = lib.any (lib.hasAttr "man") ([ finalArgs.basePackage ] ++ finalArgs.extraPackages);
        in
        {
          __structuredAttrs = true;
          name = "${finalAttrs.pname}-${finalAttrs.version}";
          pname = lib.getName finalArgs.basePackage;
          version = lib.getVersion finalArgs.basePackage;
          __intentionallyOverridingVersion = true;
          nativeBuildInputs = [
            lndir
            makeWrapper
            makeBinaryWrapper
          ];
          passthru = (finalArgs.basePackage.passthru or { }) // {
            unwrapped = finalArgs.basePackage;
          };
          outputs = [
            "out"
          ]
          ++ (lib.optional hasMan "man");
          meta = (finalArgs.basePackage.meta or { }) // {
            outputsToInstall = [
              "out"
            ]
            ++ (lib.optional hasMan "man");
          };
          buildCommand = ''
            mkdir -p $out
            for i in ${lib.escapeShellArgs ([ finalArgs.basePackage ] ++ finalArgs.extraPackages)}; do
              if test -d $i; then lndir -silent $i $out; fi
            done

            pushd "$out/bin" > /dev/null

            echo "::: Wrapping explicit .programs ..."
            already_wrapped=()
            ${lib.concatMapStringsSep "\n" (
              program:
              let
                name = program.name;
                target = if program.target == null then "" else program.target;
                wrapProgram = if program.wrapperType == "shell" then "wrapProgramShell" else "wrapProgramBinary";
                makeWrapper = if program.wrapperType == "shell" then "makeShellWrapper" else "makeBinaryWrapper";
                flags = genFlags {
                  inherit (program)
                    prependFlags
                    appendFlags
                    pathAdd
                    envVars
                    ;
                };
              in
              ''
                already_wrapped+="${program.name}"

                # If target is empty, use makeWrapper
                # If target is not empty, but the same as name, use makeWrapper
                # If target is not empty, is different from name, and doesn't exist, use wrapProgram
                # If target is not empty, is different from name, and exists, error out

                cmd=()
                if [[ -z "${target}" ]]; then
                  cmd=(${wrapProgram} "$out/bin/${name}")
                elif [[ -e "$out/bin/${name}" ]]; then
                  echo ":: Error: Target '${name}' already exists"
                  exit 1
                else
                  cmd=(${makeWrapper} "$out/bin/${target}" '${name}')
                fi

                ${
                  if flags == [ ] && program.extraWrapperFlags == "" then
                    "echo ':: (${name} skipped: no wrapper configuration)'"
                  else
                    printAndRun "\${cmd[@]} ${lib.escapeShellArgs flags} ${program.extraWrapperFlags}"
                }
              ''
            ) (lib.attrValues finalArgs.programs)}

            echo "::: Wrapping packages in out/bin ..."

            for file in "$out/bin/"*; do
              # check if $file is in $already_wrapped
              prog="$(basename "$file")"
              if [[ " ''${already_wrapped[@]} " =~ " $prog " ]]; then
                continue
              fi

              ${
                let
                  flags = genFlags {
                    inherit (finalArgs)
                      prependFlags
                      appendFlags
                      pathAdd
                      envVars
                      ;
                  };
                in
                if flags == [ ] && finalArgs.extraWrapperFlags == "" then
                  "echo \":: ($prog skipped: no wrapper configuration)\""
                else
                  printAndRun (
                    let
                      wrapProgram = if finalArgs.wrapperType == "shell" then "wrapProgramShell" else "wrapProgramBinary";
                    in
                    ''${wrapProgram} "$file" ${lib.escapeShellArgs flags} ${finalArgs.extraWrapperFlags}''
                  )
              }
            done
            popd > /dev/null

            ## Fix desktop files

            # Some derivations have nested symlinks here
            if [[ -d $out/share/applications && ! -w $out/share/applications ]]; then
              echo "Detected nested symlink, fixing"
              temp=$(mktemp -d)
              cp -v $out/share/applications/* $temp
              rm -vf $out/share/applications
              mkdir -pv $out/share/applications
              cp -v $temp/* $out/share/applications
            fi

            pushd "$out/bin" > /dev/null
            for exe in *; do
              # Fix .desktop files
              # This list of fixes might not be exhaustive
              for file in $out/share/applications/*; do
                trap "set +x" ERR
                set -x
                sed -i "s#/nix/store/.*/bin/$exe #$out/bin/$exe #" "$file"
                sed -i -E "s#Exec=$exe([[:space:]]*)#Exec=$out/bin/$exe\1#g" "$file"
                sed -i -E "s#TryExec=$exe([[:space:]]*)#TryExec=$out/bin/$exe\1#g" "$file"
                set +x
              done
            done
            popd > /dev/null

            ${lib.optionalString hasMan ''
              mkdir -p ''${!outputMan}
              ${lib.concatMapStringsSep "\n" (
                package:
                if package ? "man" then
                  "lndir -silent ${package.man} \${!outputMan}"
                else
                  "echo \"No man output for ${lib.getName package}\""
              ) ([ finalArgs.basePackage ] ++ finalArgs.extraPackages)}
            ''}

            ${finalArgs.postBuild}
          '';
        };
    };
}
