let
  keys = import ../hosts.nix;
  inherit (keys) usersKeys machinesKeys;
in
{
  "k3s.age".publicKeys = usersKeys ++ machinesKeys;
}
