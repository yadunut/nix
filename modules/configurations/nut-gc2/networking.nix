{ ... }:
{
  configurations.nixos.nut-gc2.module = {
    systemd.network.enable = true;
    systemd.network.networks."10-ens3" = {
      matchConfig.Name = "ens3";
      networkConfig = {
        DHCP = "no";
        IPv6AcceptRA = false;
      };

      address = [
        "103.149.46.7/25"
        "2a11:8083:11:13d4::a/64"
      ];
      routes = [
        { Gateway = "103.149.46.126"; }
        { Gateway = "2a11:8083:11::1"; }
      ];
    };
    networking.firewall = {
      allowedTCPPorts = [
        80
        443
      ];
    };
  };
}
