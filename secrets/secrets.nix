let
  keys = import ../keys.nix;
  inherit (keys) users machines;
in
{
  "k3s.age".publicKeys = users ++ machines;
}
