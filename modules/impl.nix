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
in
{
  options = {
    wrapped = mkOption {
      type = types.package;
      readOnly = true;
      description = "The wrapped package";
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
          pname = "''${old.pname}-wrapped";
        }
      '';
    };

    useBinaryWrapper = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Use makeBinaryWrapper instead of makeWrapper.
      '';
    };

  };

  config = {
    wrapped = pkgs.symlinkJoin {
      inherit (config.basePackage) name;
      paths = [ config.basePackage ] ++ config.extraPackages;
      nativeBuildInputs = [
        (if config.useBinaryWrapper then [ pkgs.makeBinaryWrapper ] else [ pkgs.makeWrapper ])
      ];
      postBuild = ''
        echo ":: Using ${if config.useBinaryWrapper then "binary" else "bash"} wrappers"

        pushd "$out/bin" > /dev/null

        already_wrapped=()
        ${lib.concatMapStringsSep "\n" (
          program:
          let
            target' = if program.target == null then "" else program.target;
          in
          # bash
          ''
            already_wrapped+="${program.name}"

            # If target is empty, use makeWrapper
            # If target is not empty, but the same as name, use makeWrapper
            # If target is not empty, is different from name, and doesn't exist, use wrapProgram
            # If target is not empty, is different from name, and exists, error out

            cmd=()
            if [[ -z "${target'}" || "${target'}" == "${program.name}" ]]; then
              cmd=(wrapProgram '${program.name}')
            elif [[ -e "$out/bin/${target'}" ]]; then
              echo ":: Error: Target '${target'}' already exists for ${program.name}"
              exit 1
            else
              cmd=(makeWrapper '${program.name}' '${target'}')
            fi

            ${printAndRun "\${cmd[@]} ${lib.escapeShellArgs program.wrapFlags} ${program.extraWrapperFlags}"}
          ''
        ) (attrValues config.programs)}

        for file in "$out/bin/"*; do
          # check if $file is in $already_wrapped
          if [[ " ''${already_wrapped[@]} " =~ " ''${file} " ]]; then
            echo ":: Skipping already wrapped program: $file"
            continue
          fi

          ${printAndRun ''wrapProgram "$file" ${lib.escapeShellArgs config.wrapFlags} ${config.extraWrapperFlags}''}
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
      '';
    };
  };
}
