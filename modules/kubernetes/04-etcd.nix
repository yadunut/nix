{
  flake.modules.nixos.kubernetes-controller =
    {
      pkgs,
      config,
      lib,
      clanLib ? null,
      roles ? { },
      ...
    }:
    let
      generators = config.clan.core.vars.generators;
      hostname = config.networking.hostName;
      nodeIp = config.nut.kubernetes.nodeIP;

      # Get list of controller machine names from roles
      controllerMachineNames = builtins.attrNames (roles.controller.machines or { });

      # Helper function to get zerotier IP for a given machine
      getZerotierIp =
        machineName:
        clanLib.getPublicValue {
          flake = config.clan.core.settings.directory;
          machine = machineName;
          generator = "zerotier";
          file = "zerotier-ip";
        };

      # Generate the initial cluster string: "node1=https://[ip1]:2380,node2=https://[ip2]:2380,..."
      initialClusterMembers = lib.concatMapStringsSep "," (
        machineName:
        let
          ip = getZerotierIp machineName;
        in
        "${machineName}=https://[${ip}]:2380"
      ) controllerMachineNames;

      # Generate the list of etcd endpoints for API server: "https://[ip1]:2379,https://[ip2]:2379,..."
      etcdEndpoints = lib.concatMapStringsSep "," (
        machineName:
        let
          ip = getZerotierIp machineName;
        in
        "https://[${ip}]:2379"
      ) controllerMachineNames;
    in
    {
      environment.systemPackages = [ pkgs.etcd ];

      services.etcd = {
        enable = true;
        name = hostname;

        # Listen addresses (using ZeroTier IPv6)
        listenClientUrls = [
          "https://[${nodeIp}]:2379"
          "https://[::1]:2379"
        ];
        advertiseClientUrls = [ "https://[${nodeIp}]:2379" ];

        listenPeerUrls = [ "https://[${nodeIp}]:2380" ];
        initialAdvertisePeerUrls = [ "https://[${nodeIp}]:2380" ];

        # Cluster configuration
        initialCluster = lib.splitString "," initialClusterMembers;
        initialClusterState = "new";
        initialClusterToken = "kubernetes-etcd-cluster";

        # TLS configuration for client connections
        clientCertAuth = true;
        trustedCaFile = generators.etcd-ca-crt.files."ca.crt".path;
        certFile = generators.etcd-server-crt.files."etcd-server.crt".path;
        keyFile = generators.etcd-server-crt.files."etcd-server.key".path;

        # TLS configuration for peer connections
        peerClientCertAuth = true;
        peerTrustedCaFile = generators.etcd-ca-crt.files."ca.crt".path;
        peerCertFile = generators.etcd-peer-crt.files."etcd-peer.crt".path;
        peerKeyFile = generators.etcd-peer-crt.files."etcd-peer.key".path;

        # Data directory
        dataDir = "/var/lib/etcd";
      };

      # Export etcdEndpoints for other modules (like kube-apiserver) to use
      nut.kubernetes.etcd = {
        endpoints = etcdEndpoints;
        initialCluster = initialClusterMembers;
      };
    };
}
