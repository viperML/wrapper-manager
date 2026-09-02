''
wrapper-manager has migrated to Codeberg! You are currently using
the old GitHub input, which will continue to work until October 31st.

To perform the migration, please do the following:

- If you are using npins:

  npins add forgejo codeberg.org viperML wrapper-manager --branch master

- If you are using flakes:

  sed -i 's#github:viperML/wrapper-manager#git+https://codeberg.org/viperML/wrapper-manager#g' ./flake.nix
  nix flake update --flake . wrapper-manager

- Otherwise:

  sed -i 's#github.com/viperML/wrapper-manager#codeberg.org/viperML/wrapper-manager#g'

If you have any issues during the migration, please open a bug report!
https://codeberg.org/viperML/wrapper-manager/issues
''
