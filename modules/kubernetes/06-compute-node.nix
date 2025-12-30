{
  flake.modules.nixos.kubernetes-compute =
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
      clusterName = config.nut.kubernetes.instanceName;
      nodeIP = config.nut.kubernetes.nodeIP;
      hostname = config.networking.hostName;
      clusterDomain = config.nut.kubernetes.domain;
      serviceCIDR = config.nut.kubernetes.serviceCIDR;

      # Calculate DNS IP from service CIDR (10th IP in the CIDR range)
      # For IPv6 CIDR like "fd00:10:97::/108", the DNS IP is typically the 10th address (0xa in hex)
      calculateDNSIP =
        cidr:
        let
          parts = lib.splitString "/" cidr;
          baseAddr = lib.head parts;
          cleanAddr = lib.removeSuffix "]" (lib.removePrefix "[" baseAddr);
          dnsIP = lib.replaceStrings [ "::" ] [ "::a" ] cleanAddr;
        in
        dnsIP;

      clusterDNS = calculateDNSIP serviceCIDR;

      # Get API server endpoint:
      # 1. Use configured option (which defaults to service-level setting)
      # 2. Auto-detect from first controller node via clanLib
      # 3. Fallback to local node IP (for control-plane nodes that also run kubelet)
      apiServerEndpoint =
        if config.nut.kubernetes.apiServerEndpoint != null then
          config.nut.kubernetes.apiServerEndpoint
        else if clanLib != null && (roles.controller.machines or { }) != { } then
          let
            controllerMachineNames = builtins.attrNames roles.controller.machines;
            firstController = lib.head controllerMachineNames;
            getZerotierIp =
              machineName:
              clanLib.getPublicValue {
                flake = config.clan.core.settings.directory;
                machine = machineName;
                generator = "zerotier";
                file = "zerotier-ip";
              };
          in
          "https://[${getZerotierIp firstController}]:6443"
        else
          "https://[${nodeIP}]:6443"; # Fallback to local node IP (for control-plane nodes that also run kubelet)
    in
    {
      environment.systemPackages = [ pkgs.kubernetes ];

      # Enable containerd for container runtime
      virtualisation.containerd.enable = true;
      # Use /opt/cni/bin directly - both NixOS CNI plugins and Cilium will live here
      virtualisation.containerd.settings.plugins."io.containerd.grpc.v1.cri".cni.bin_dir =
        lib.mkForce "/opt/cni/bin";

      # Create /opt/cni/bin directory and symlink all NixOS CNI plugins there
      # Cilium will install its cilium-cni plugin to the same directory
      # Note: Cilium may overwrite the loopback symlink with its own binary, which is fine
      systemd.tmpfiles.rules = [
        "d /opt/cni/bin 0755 root root -"
        # Symlink all NixOS CNI plugins to /opt/cni/bin
        "L+ /opt/cni/bin/bridge - - - - ${pkgs.cni-plugins}/bin/bridge"
        "L+ /opt/cni/bin/dhcp - - - - ${pkgs.cni-plugins}/bin/dhcp"
        "L+ /opt/cni/bin/firewall - - - - ${pkgs.cni-plugins}/bin/firewall"
        "L+ /opt/cni/bin/host-device - - - - ${pkgs.cni-plugins}/bin/host-device"
        "L+ /opt/cni/bin/host-local - - - - ${pkgs.cni-plugins}/bin/host-local"
        "L+ /opt/cni/bin/ipvlan - - - - ${pkgs.cni-plugins}/bin/ipvlan"
        "L+ /opt/cni/bin/loopback - - - - ${pkgs.cni-plugins}/bin/loopback"
        "L+ /opt/cni/bin/macvlan - - - - ${pkgs.cni-plugins}/bin/macvlan"
        "L+ /opt/cni/bin/portmap - - - - ${pkgs.cni-plugins}/bin/portmap"
        "L+ /opt/cni/bin/ptp - - - - ${pkgs.cni-plugins}/bin/ptp"
        "L+ /opt/cni/bin/sbr - - - - ${pkgs.cni-plugins}/bin/sbr"
        "L+ /opt/cni/bin/static - - - - ${pkgs.cni-plugins}/bin/static"
        "L+ /opt/cni/bin/tuning - - - - ${pkgs.cni-plugins}/bin/tuning"
        "L+ /opt/cni/bin/vlan - - - - ${pkgs.cni-plugins}/bin/vlan"
        "L+ /opt/cni/bin/vrf - - - - ${pkgs.cni-plugins}/bin/vrf"
        # Symlink kubelet kubeconfig
        "L+ /var/lib/kubelet/kubelet.kubeconfig - - - - ${
          generators.kubernetes-kubelet-kubeconfig.files."kubelet.kubeconfig".path
        }"
      ];

      # Enable IPv6 forwarding for pod networking (required even without CNI for now)
      # Use mkDefault to avoid conflicts with other modules (e.g., wireguard) setting the same value
      boot.kernel.sysctl = {
        "net.ipv6.conf.all.forwarding" = lib.mkDefault 1;
      };

      # Generate kubelet kubeconfig
      clan.core.vars.generators = {
        kubernetes-kubelet-kubeconfig = {
          share = false;
          files."kubelet.kubeconfig" = {
            secret = true;
            owner = "kubernetes";
            group = "kubernetes";
            mode = "0440";
          };
          dependencies = [
            "kubernetes-ca-crt"
            "kubernetes-kubelet-client-crt"
          ];
          runtimeInputs = [ pkgs.kubectl ];
          script = ''
            kubectl config set-cluster ${clusterName} \
              --certificate-authority=$in/kubernetes-ca-crt/ca.crt \
              --embed-certs=true \
              --server=${apiServerEndpoint} \
              --kubeconfig=$out/kubelet.kubeconfig

            kubectl config set-credentials system:node:${hostname} \
              --client-certificate=$in/kubernetes-kubelet-client-crt/kubelet-client.crt \
              --client-key=$in/kubernetes-kubelet-client-crt/kubelet-client.key \
              --embed-certs=true \
              --kubeconfig=$out/kubelet.kubeconfig

            kubectl config set-context default \
              --cluster=${clusterName} \
              --user=system:node:${hostname} \
              --kubeconfig=$out/kubelet.kubeconfig

            kubectl config use-context default \
              --kubeconfig=$out/kubelet.kubeconfig
          '';
        };
      };

      # Kubelet configuration file
      # Using static certificates with rotateCertificates for auto-renewal
      environment.etc."kubernetes/config/kubelet-config.yaml".text = ''
        apiVersion: kubelet.config.k8s.io/v1beta1
        kind: KubeletConfiguration
        authentication:
          x509:
            clientCAFile: "/var/lib/kubelet/ca.crt"
        authorization:
          mode: Webhook
        clusterDomain: "${clusterDomain}"
        clusterDNS:
          - "${clusterDNS}"
        cgroupDriver: "systemd"
        failSwapOn: false
        serializeImagePulls: false
        # Static TLS certificates (generated by clan vars)
        tlsCertFile: "/var/lib/kubelet/kubelet-server.crt"
        tlsPrivateKeyFile: "/var/lib/kubelet/kubelet-server.key"
        # Enable certificate rotation for client certs (kubelet will request renewal before expiry)
        rotateCertificates: true
        evictionHard:
          memory.available: "200Mi"
          nodefs.available: "10%"
          nodefs.inodesFree: "5%"
        evictionSoft:
          memory.available: "200Mi"
        evictionSoftGracePeriod:
          memory.available: "1m"
        evictionMaxPodGracePeriod: 30
        evictionPressureTransitionPeriod: "30s"
        tlsCipherSuites:
          - "TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256"
          - "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256"
          - "TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305"
          - "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384"
          - "TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305"
          - "TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384"
      '';

      # Firewall rules for Cilium CNI
      # Trust cilium_host, cilium_net, and lxc* interfaces (used for pod networking)
      # lxc* interfaces are veth pairs connecting pods to the host
      networking.firewall.trustedInterfaces = [
        "cilium_host"
        "cilium_net"
        "lxc*"
      ];

      # Allow forwarding for pod traffic on Cilium interfaces
      networking.firewall.extraForwardRules = ''
        iifname "cilium_host" accept
        oifname "cilium_host" accept
        iifname "lxc*" accept
        oifname "lxc*" accept
      '';

      # Disable reverse path filtering for Cilium
      # rpfilter drops packets that don't match the expected source path, which breaks
      # BPF-based networking where packets may arrive on unexpected interfaces
      networking.firewall.checkReversePath = false;

      # Kubelet systemd service
      # Kubelet runs as root because it needs to manage containers, networking, volumes, and cgroups
      systemd.services."kubelet" = {
        description = "Kubernetes Kubelet";
        documentation = [ "https://github.com/kubernetes/kubernetes" ];
        wantedBy = [ "kubernetes.target" ];
        after = [
          "network.target"
          "containerd.service"
          "systemd-tmpfiles-setup.service"
        ];
        requires = [ "containerd.service" ];

        # mount is required for kubelet to mount volumes (secrets, configmaps, etc.)
        path = [ pkgs.util-linux ];

        serviceConfig = {
          ExecStart = ''
            ${pkgs.kubernetes}/bin/kubelet \
              --config=/etc/kubernetes/config/kubelet-config.yaml \
              --kubeconfig=/var/lib/kubelet/kubelet.kubeconfig \
              --cert-dir=/var/lib/kubelet/pki \
              --container-runtime-endpoint=unix:///run/containerd/containerd.sock \
              --node-ip=${nodeIP} \
              --pod-infra-container-image=registry.k8s.io/pause:3.9 \
              --register-node=true \
              --v=2
          '';
          Restart = "on-failure";
          RestartSec = 5;
          # Kubelet requires root privileges for container management, networking, and cgroups
        };
      };
    };
}
