{ ... }:
{
  flake.modules.nixos.base =
    { ... }:
    {
      networking = {
        nftables.enable = true;
        firewall.enable = true;
      };
    };
}
