{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib) mkOption types;
  inherit (builtins) attrValues;
in
{
  options = {
    wrapped = mkOption {
      type = types.package;
      readOnly = true;
    };

    overrideAttrs = mkOption {
      type = with types; functionTo attrs;
      description = ''
        Function to override attributes from the final package.
      '';
      default = lib.id;
      defaultText = lib.literalExression "lib.id";
      example = lib.literalExpression ''
        old: {
          pname = "''${old.pname}-wrapped";
        }
      '';
    };

  };

  config = {
    wrapped = pkgs.symlinkJoin {
      inherit (config.basePackage) name;
      paths = [ config.basePackage ] ++ config.extraPackages;
      # TODO: Handle binary wrappers
      nativeBuildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        already_wrapped=()

        ${lib.concatMapStringsSep "\n" (
          program:
          # bash
          ''
            echo ":: Wrapping ${program.name}"
            already_wrapped+="${program.name}"
          '') (attrValues config.programs)}

        pushd "$out/bin" > /dev/null
        for file in *; do
          # check if $file is in $already_wrapped
          if [[ " ''${already_wrapped[@]} " =~ " ''${file} " ]]; then
            echo ":: Skipping already wrapped program: $file"
            continue
          fi
          echo ":: Wrapping $file"

          wrapProgram \
            "$file" \
            ${lib.escapeShellArgs config.wrapFlags} \
            ${config.extraWrapperFlags}
        done
        popd > /dev/null

        # Some derivations have nested symlinks here
        if [[ -d $out/share/applications && ! -w $out/share/applications ]]; then
          echo "Detected nested symlink, fixing"
          temp=$(mktemp -d)
          cp -v $out/share/applications/* $temp
          rm -vf $out/share/applications
          mkdir -pv $out/share/applications
          cp -v $temp/* $out/share/applications
        fi
      '';
    };
  };
}
