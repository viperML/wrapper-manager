{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib) mkOption types;
  inherit (builtins) attrValues;

  printAndRun = cmd: ''
    echo ":: ${cmd}"
    eval "${cmd}"
  '';

  hasMan = builtins.any (builtins.hasAttr "man") ([ config.basePackage ] ++ config.extraPackages);
in
{
  options = {
    wrapped = mkOption {
      type = types.package;
      readOnly = true;
      description = "(Read-only) The final wrapped package";
    };

    overrideAttrs = mkOption {
      type = with types; functionTo attrs;
      description = ''
        Function to override attributes from the final package.
      '';
      default = lib.id;
      defaultText = lib.literalExpression "lib.id";
      example = lib.literalExpression ''
        old: {
          pname = "''${pname}-with-settings";
        }
      '';
    };

    postBuild = mkOption {
      type = types.str;
      default = "";
      description = "Raw commands to execute after the wrapping process has finished";
      example = ''
        echo "Running sanity check"
        $out/bin/nvim '+q'
      '';
    };
  };

  config = {
    wrapped =
      (
        (pkgs.symlinkJoin {
          # inherit (config.basePackage) name;
          pname = lib.getName config.basePackage;
          version = lib.getVersion config.basePackage;
          __intentionallyOverridingVersion = true;
          paths = [ config.basePackage ] ++ config.extraPackages;
          nativeBuildInputs = [
            pkgs.makeBinaryWrapper
            pkgs.makeWrapper
          ];
          passthru = (config.basePackage.passthru or { }) // {
            unwrapped = config.basePackage;
          };
          outputs = [
            "out"
          ] ++ (lib.optional hasMan "man");
          meta = (config.basePackage.meta or { }) // {
            outputsToInstall = [
              "out"
            ] ++ (lib.optional hasMan "man");
          };
          postBuild = ''
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
              in
              # bash
              ''
                already_wrapped+="${program.name}"

                # If target is empty, use makeWrapper
                # If target is not empty, but the same as name, use makeWrapper
                # If target is not empty, is different from name, and doesn't exist, use wrapProgram
                # If target is not empty, is different from name, and exists, error out

                cmd=()
                if [[ -z "${target}" ]]; then
                  cmd=(${wrapProgram} '${name}')
                elif [[ -e "$out/bin/${name}" ]]; then
                  echo ":: Error: Target '${name}' already exists"
                  exit 1
                else
                  cmd=(${makeWrapper} "$out/bin/${target}" '${name}')
                fi

                ${
                  if program.wrapFlags == [ ] && program.extraWrapperFlags == "" then
                    "echo ':: (${name} skipped: no wrapper configuration)'"
                  else
                    printAndRun "\${cmd[@]} ${lib.escapeShellArgs program.wrapFlags} ${program.extraWrapperFlags}"
                }
              ''
            ) (attrValues config.programs)}

            echo "::: Wrapping packages in out/bin ..."

            for file in "$out/bin/"*; do
              # check if $file is in $already_wrapped
              prog="$(basename "$file")"
              if [[ " ''${already_wrapped[@]} " =~ " $prog " ]]; then
                continue
              fi

              ${
                if config.wrapFlags == [ ] && config.extraWrapperFlags == "" then
                  "echo \":: ($prog skipped: no wrapper configuration)\""
                else
                  printAndRun (
                    let
                      wrapProgram = if config.wrapperType == "shell" then "wrapProgramShell" else "wrapProgramBinary";
                    in
                    ''${wrapProgram} "$file" ${lib.escapeShellArgs config.wrapFlags} ${config.extraWrapperFlags}''
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
                p:
                if p ? "man" then
                  "${lib.getExe pkgs.xorg.lndir} -silent ${p.man} \${!outputMan}"
                else
                  "echo \"No man output for ${lib.getName p}\""
              ) ([ config.basePackage ] ++ config.extraPackages)}
            ''}

            ${config.postBuild}
          '';
        }).overrideAttrs
        (
          final: prev: {
            name = "${final.pname}-${final.version}";
          }
        )
      ).overrideAttrs
        config.overrideAttrs;
  };
}
