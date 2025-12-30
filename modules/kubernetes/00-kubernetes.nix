{ config, ... }:
{
  flake.modules.nixos.kubernetes-compute = { };
  flake.modules.nixos.kubernetes-controller = {
    users.groups.etcd = { };
    users.users.etcd = {
      isSystemUser = true;
      group = "etcd";
    };
    users.users.kubernetes.extraGroups = [ "etcd" ];
  };
  flake.modules.nixos.kubernetes-common =
    {
      config,
      lib,
      inputs,
      settings,
      instanceName ? null,
      ...
    }:
    {
      options.nut.kubernetes = {
        instanceName = lib.mkOption {
          type = lib.types.str;
          description = "Kubernetes cluster instance name (used for service identification).";
        };
        nodeIP = lib.mkOption {
          type = lib.types.str;
          description = "IPv6 address of this node (typically the ZeroTier IP).";
          default = config.clan.core.vars.generators.zerotier.files.zerotier-ip.value;
        };
        clusterCIDR = lib.mkOption {
          type = lib.types.str;
          description = "CIDR range for pod IPs.";
          default = settings.clusterCIDR or "fd00:10:96::/48";
        };
        serviceCIDR = lib.mkOption {
          type = lib.types.str;
          description = "CIDR range for service IPs.";
          default = settings.serviceCIDR or "fd00:10:97::/108";
        };
        domain = lib.mkOption {
          type = lib.types.str;
          description = "Domain suffix to use for hostname aliases";
          default = settings.domain or "k8s.internal";
        };
        etcd = {
          endpoints = lib.mkOption {
            type = lib.types.str;
            description = "Comma-separated list of etcd endpoints for kube-apiserver.";
            default = "";
          };
          initialCluster = lib.mkOption {
            type = lib.types.str;
            description = "Initial cluster configuration for etcd.";
            default = "";
          };
        };
        apiServerEndpoint = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          description = "API server endpoint URL (e.g., https://[ip]:6443). If null, will auto-detect from first control-plane node.";
          default = settings.apiServerEndpoint or null;
        };
      };
      config = {
        nut.kubernetes.instanceName = lib.mkDefault instanceName;

        users.groups.kubernetes.gid = config.ids.gids.kubernetes;
        users.users.kubernetes = {
          uid = config.ids.uids.kubernetes;
          description = "Kubernetes user";
          group = "kubernetes";
          home = "/var/lib/kubernetes";
          createHome = true;
          homeMode = "755";
        };
        users.users.yadunut.extraGroups = [ "kubernetes" ];
        systemd.targets.kubernetes = {
          description = "Kubernetes";
          wantedBy = [ "multi-user.target" ];
        };

        systemd.tmpfiles.rules = [
          # Root ownership to allow subdirectories with different owners (pki, etcd)
          "d /var/lib/kubernetes 0755 root root -"
        ];
      };
    };

  flake.modules."clan.service".kubernetes =
    { inputs, clanLib, ... }:
    let
      # common options for all Kubernetes machines
      sharedInterface =
        { lib, ... }:
        {
          options.clusterCIDR = lib.mkOption {
            type = lib.types.str;
            description = "CIDR range for pod IPs.";
            default = "fd00:10:96::/48";
          };
          options.serviceCIDR = lib.mkOption {
            type = lib.types.str;
            description = "CIDR range for service IPs.";
            default = "fd00:10:97::/108";
          };
          options.domain = lib.mkOption {
            type = lib.types.str;
            default = "k8s.internal";
            description = "Domain suffix to use for hostname aliases in /etc/hosts";
          };
          options.apiServerEndpoint = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "API server endpoint URL. If null, auto-detected from first controller node.";
          };
        };
    in
    {
      manifest.name = "kubernetes";

      roles.controller = {
        interface =
          { ... }:
          {
            imports = [ sharedInterface ];
          };
        perInstance =
          {
            settings,
            instanceName,
            roles,
            ...
          }:
          {
            nixosModule = {
              _module.args = {
                inherit
                  settings
                  instanceName
                  roles
                  clanLib
                  ;
              };
              imports = with config.flake.modules.nixos; [
                kubernetes-controller
                kubernetes-common
              ];
            };
          };
      };
      roles.compute = {
        interface =
          { ... }:
          {
            imports = [ sharedInterface ];
          };
        perInstance =
          {
            settings,
            instanceName,
            roles,
            machine,
            ...
          }:
          let
            isAlsoController = roles.controller.machines ? ${machine.name};
          in
          {
            nixosModule = {
              imports =
                with config.flake.modules.nixos;
                [ kubernetes-compute ] ++ (if isAlsoController then [ ] else [ kubernetes-common ]);
            }
            # Only set _module.args if not also a controller (controller role already sets them)
            // (
              if isAlsoController then
                { }
              else
                {
                  _module.args = {
                    inherit
                      settings
                      instanceName
                      roles
                      clanLib
                      ;
                  };
                }
            );
          };
      };
    };

  flake.modules.clan.kubernetes = {
    inventory.instances.nut-cluster = {
      module.name = "@yadunut/kubernetes";
      module.input = "self";

      roles.controller.machines.nut-gc1 = { };
      # roles.controller.machines.nut-gc2 = { };

      roles.compute.machines.nut-gc1 = { };
      roles.compute.machines.nut-gc2 = { };
      roles.compute.machines.premhome-eagle-1 = { };
      roles.compute.machines.premhome-falcon-1 = { };
    };
  };
  perSystem =
    { pkgs, ... }:
    {
      make-shells.default.packages = [
        pkgs.step-cli
        pkgs.openssl
      ];
    };
}
