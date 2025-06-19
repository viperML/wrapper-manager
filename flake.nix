{
  outputs =
    _:
    let
      toplevel = import ./default.nix;
    in
    {
      lib = toplevel.v2;
    };
}
