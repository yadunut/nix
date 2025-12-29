{
  flake.modules.nixos.kubernetes-common =
    { pkgs, ... }:
    {
      clan.core.vars.generators = {
        # Kubernetes CA (signs all Kubernetes component certificates)
        kubernetes-ca-crt = {
          share = true;
          files."ca.key" = {
            secret = true;
            mode = "0440";
            owner = "kubernetes";
            group = "kubernetes";
          };
          files."ca.crt".secret = false;

          runtimeInputs = [ pkgs.step-cli ];
          script = ''
            step certificate create "kubernetes-ca" $out/ca.crt $out/ca.key \
            --profile root-ca \
            --no-password --insecure --not-after 87600h
          '';
        };
        # etcd CA (signs all etcd-related certificates)
        etcd-ca-crt = {
          share = true;
          files."ca.key".secret = true;
          files."ca.key".mode = "0440";
          files."ca.crt".secret = false;

          runtimeInputs = [ pkgs.step-cli ];
          script = ''
            step certificate create "etcd-ca" $out/ca.crt $out/ca.key \
            --profile root-ca \
            --no-password --insecure --not-after 87600h
          '';
        };
        # Admin certificate for kubectl
        kubernetes-admin-crt = {
          share = true;
          files."admin.key" = {
            secret = true;
            mode = "0440";
          };
          files."admin.crt".secret = false;

          dependencies = [ "kubernetes-ca-crt" ];
          runtimeInputs = [ pkgs.step-cli ];
          script = ''
            cat > admin.tpl <<EOF
            {
              "subject": {
                "commonName": "kubernetes-admin",
                "organization": ["system:masters"]
              },
              "keyUsage": ["digitalSignature", "keyEncipherment"],
              "basicConstraints": { "isCA": false },
              "extKeyUsage": ["clientAuth"]
            }
            EOF

            step certificate create admin $out/admin.crt $out/admin.key \
            --template admin.tpl \
            --ca $in/kubernetes-ca-crt/ca.crt \
            --ca-key $in/kubernetes-ca-crt/ca.key \
            --no-password --insecure \
            --not-after 8760h
          '';
        };
      };
    };

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
      hostname = config.networking.hostName;
      nodeIp = config.nut.kubernetes.nodeIP;
      serviceCIDR = config.nut.kubernetes.serviceCIDR;
      clusterDomain = config.nut.kubernetes.domain;
      generators = config.clan.core.vars.generators;

      # Get list of controller machine names from roles
      controllerMachineNames = builtins.attrNames (roles.controller.machines or { });

      # Helper function to get zerotier IP for a given machine
      getZerotierIp =
        machineName:
        if clanLib != null then
          clanLib.getPublicValue {
            flake = config.clan.core.settings.directory;
            machine = machineName;
            generator = "zerotier";
            file = "zerotier-ip";
          }
        else
          null;

      # Get all controller IPs for API server SANs (for HA)
      allControllerIps = lib.filter (ip: ip != null) (map getZerotierIp controllerMachineNames);

      # Calculate first service IP from service CIDR (for kubernetes.default ClusterIP)
      # For "fd00:10:97::/108", the first usable IP is "fd00:10:97::1"
      calculateFirstServiceIP =
        cidr:
        let
          parts = lib.splitString "/" cidr;
          baseAddr = lib.head parts;
          cleanAddr = lib.removeSuffix "]" (lib.removePrefix "[" baseAddr);
          # Replace "::" with "::1" to get the first usable address
          firstIP = lib.replaceStrings [ "::" ] [ "::1" ] cleanAddr;
        in
        firstIP;

      kubernetesServiceIP = calculateFirstServiceIP serviceCIDR;

      # Helper function to generate a certificate signed by kubernetes CA
      mkK8sCertificate =
        {
          name,
          commonName,
          orgs ? [ ],
          extKeyUsage ? [ "clientAuth" ],
          sans ? [ ],
          keyOwner ? "kubernetes",
          keyGroup ? "kubernetes",
          share ? false,
        }:
        {
          inherit share;
          files."${name}.key" = {
            secret = true;
            owner = keyOwner;
            group = keyGroup;
            mode = "0440";
          };
          files."${name}.crt" = {
            secret = false;
          };

          dependencies = [ "kubernetes-ca-crt" ];
          runtimeInputs = [ pkgs.step-cli ];
          script = ''
            cat > ${name}.tpl <<EOF
            {
              "subject": {
                "commonName": "${commonName}"${
                  if orgs != [ ] then ",\n                  \"organization\": ${builtins.toJSON orgs}" else ""
                }
              },
              "keyUsage": ["digitalSignature", "keyEncipherment"],
              "basicConstraints": { "isCA": false },
              "extKeyUsage": ${builtins.toJSON extKeyUsage}${
                if sans != [ ] then ",\n              \"sans\": {{ toJson .SANs }}" else ""
              }
            }
            EOF

            step certificate create ${name} $out/${name}.crt $out/${name}.key \
            --template ${name}.tpl \
            --ca $in/kubernetes-ca-crt/ca.crt \
            --ca-key $in/kubernetes-ca-crt/ca.key \
            --no-password --insecure \
            --not-after 8760h \
            ${builtins.concatStringsSep " " (map (san: "--san ${san}") sans)}
          '';
        };

      # Helper function to generate a certificate signed by etcd CA
      mkEtcdCertificate =
        {
          name,
          commonName,
          orgs ? [ ],
          extKeyUsage ? [ "clientAuth" ],
          sans ? [ ],
          keyOwner ? "etcd",
          keyGroup ? "etcd",
          share ? false,
        }:
        {
          inherit share;
          files."${name}.key" = {
            secret = true;
            owner = keyOwner;
            group = keyGroup;
            mode = "0440";
          };
          files."${name}.crt" = {
            secret = false;
          };

          dependencies = [ "etcd-ca-crt" ];
          runtimeInputs = [ pkgs.step-cli ];
          script = ''
            cat > ${name}.tpl <<EOF
            {
              "subject": {
                "commonName": "${commonName}"${
                  if orgs != [ ] then ",\n                  \"organization\": ${builtins.toJSON orgs}" else ""
                }
              },
              "keyUsage": ["digitalSignature", "keyEncipherment"],
              "basicConstraints": { "isCA": false },
              "extKeyUsage": ${builtins.toJSON extKeyUsage}${
                if sans != [ ] then ",\n              \"sans\": {{ toJson .SANs }}" else ""
              }
            }
            EOF

            step certificate create ${name} $out/${name}.crt $out/${name}.key \
            --template ${name}.tpl \
            --ca $in/etcd-ca-crt/ca.crt \
            --ca-key $in/etcd-ca-crt/ca.key \
            --no-password --insecure \
            --not-after 8760h \
            ${builtins.concatStringsSep " " (map (san: "--san ${san}") sans)}
          '';
        };
    in
    {
      clan.core.vars.generators = {

        # Service account key pair (not a certificate)
        kubernetes-service-account-keys = {
          share = true;
          files."sa.key" = {
            secret = true;
            mode = "0440";
            owner = "kubernetes";
            group = "kubernetes";
          };
          files."sa.pub".secret = false;

          runtimeInputs = [ pkgs.openssl ];
          script = ''
            # Generate ECDSA P-256 private key
            openssl ecparam -genkey -name prime256v1 -noout -out sa.key
            # Extract public key from private key
            openssl ec -in sa.key -pubout -out sa.pub
            mv sa.key $out/sa.key
            mv sa.pub $out/sa.pub
          '';
        };

        # Kubernetes API Server certificate
        # SANs include all controller IPs for HA, plus the kubernetes service ClusterIP
        kubernetes-apiserver-crt = mkK8sCertificate {
          name = "apiserver";
          commonName = "kube-apiserver";
          extKeyUsage = [
            "serverAuth"
            "clientAuth"
          ];
          keyOwner = "kubernetes";
          keyGroup = "kubernetes";
          sans = [
            "127.0.0.1"
            "::1"
            "localhost"
            "kubernetes"
            "kubernetes.default"
            "kubernetes.default.svc"
            "kubernetes.default.svc.${clusterDomain}"
            hostname
            nodeIp
            kubernetesServiceIP # First service IP for kubernetes.default ClusterIP
          ]
          ++ allControllerIps; # All controller IPs for HA
        };

        # API Server etcd client certificate (signed by etcd CA)
        kubernetes-apiserver-etcd-client-crt = mkEtcdCertificate {
          name = "apiserver-etcd-client";
          commonName = "kube-apiserver-etcd-client";
          extKeyUsage = [ "clientAuth" ];
          keyOwner = "kubernetes";
          keyGroup = "kubernetes";
        };

        # API Server kubelet client certificate
        kubernetes-apiserver-kubelet-client-crt = mkK8sCertificate {
          name = "apiserver-kubelet-client";
          commonName = "kube-apiserver-kubelet-client";
          extKeyUsage = [ "clientAuth" ];
        };

        # Controller Manager certificate
        kubernetes-controller-manager-crt = mkK8sCertificate {
          name = "controller-manager";
          commonName = "system:kube-controller-manager";
          orgs = [ "system:kube-controller-manager" ];
          extKeyUsage = [ "clientAuth" ];
        };

        # Scheduler certificate
        kubernetes-scheduler-crt = mkK8sCertificate {
          name = "scheduler";
          commonName = "system:kube-scheduler";
          orgs = [ "system:kube-scheduler" ];
          extKeyUsage = [ "clientAuth" ];
        };

        # etcd server certificate (per control-plane node)
        etcd-server-crt = mkEtcdCertificate {
          name = "etcd-server";
          commonName = "kube-etcd";
          extKeyUsage = [
            "serverAuth"
            "clientAuth"
          ];
          sans = [
            hostname
            "127.0.0.1"
            "::1"
            "localhost"
            nodeIp
          ];
        };

        # etcd peer certificate (per control-plane node)
        etcd-peer-crt = mkEtcdCertificate {
          name = "etcd-peer";
          commonName = "kube-etcd-peer";
          extKeyUsage = [
            "serverAuth"
            "clientAuth"
          ];
          sans = [
            hostname
            "127.0.0.1"
            "::1"
            "localhost"
            nodeIp
          ];
        };

        # etcd healthcheck client certificate (shared)
        etcd-healthcheck-client-crt = mkEtcdCertificate {
          name = "etcd-healthcheck-client";
          commonName = "kube-etcd-healthcheck-client";
          extKeyUsage = [ "clientAuth" ];
          share = true;
        };

        # Kubelet server certificate (per node)
        kubernetes-kubelet-server-crt = mkK8sCertificate {
          name = "kubelet-server";
          commonName = "system:node:${hostname}";
          orgs = [ "system:nodes" ];
          extKeyUsage = [ "serverAuth" ];
          sans = [
            hostname
            "127.0.0.1"
            "::1"
            "localhost"
            nodeIp
          ];
        };

        # Kubelet client certificate (per node)
        kubernetes-kubelet-client-crt = mkK8sCertificate {
          name = "kubelet-client";
          commonName = "system:node:${hostname}";
          orgs = [ "system:nodes" ];
          extKeyUsage = [ "clientAuth" ];
        };
      };

      systemd.tmpfiles.rules = [
        # Create PKI directory structure
        "d /var/lib/kubernetes/pki 0755 root root -"
        "d /var/lib/kubernetes/pki/etcd 0755 etcd etcd -"
        "d /var/lib/etcd 0755 etcd etcd -"
        "d /var/lib/kubelet 0755 root root -"

        # Kubernetes CA
        "L+ /var/lib/kubernetes/pki/ca.crt - - - - ${generators.kubernetes-ca-crt.files."ca.crt".path}"
        "L+ /var/lib/kubernetes/pki/ca.key - - - - ${generators.kubernetes-ca-crt.files."ca.key".path}"

        # etcd CA
        "L+ /var/lib/kubernetes/pki/etcd/ca.crt - - - - ${generators.etcd-ca-crt.files."ca.crt".path}"
        "L+ /var/lib/kubernetes/pki/etcd/ca.key - - - - ${generators.etcd-ca-crt.files."ca.key".path}"

        # API Server certificates
        "L+ /var/lib/kubernetes/pki/apiserver.crt - - - - ${
          generators.kubernetes-apiserver-crt.files."apiserver.crt".path
        }"
        "L+ /var/lib/kubernetes/pki/apiserver.key - - - - ${
          generators.kubernetes-apiserver-crt.files."apiserver.key".path
        }"
        "L+ /var/lib/kubernetes/pki/apiserver-etcd-client.crt - - - - ${
          generators.kubernetes-apiserver-etcd-client-crt.files."apiserver-etcd-client.crt".path
        }"
        "L+ /var/lib/kubernetes/pki/apiserver-etcd-client.key - - - - ${
          generators.kubernetes-apiserver-etcd-client-crt.files."apiserver-etcd-client.key".path
        }"
        "L+ /var/lib/kubernetes/pki/apiserver-kubelet-client.crt - - - - ${
          generators.kubernetes-apiserver-kubelet-client-crt.files."apiserver-kubelet-client.crt".path
        }"
        "L+ /var/lib/kubernetes/pki/apiserver-kubelet-client.key - - - - ${
          generators.kubernetes-apiserver-kubelet-client-crt.files."apiserver-kubelet-client.key".path
        }"

        # Controller Manager certificate
        "L+ /var/lib/kubernetes/pki/controller-manager.crt - - - - ${
          generators.kubernetes-controller-manager-crt.files."controller-manager.crt".path
        }"
        "L+ /var/lib/kubernetes/pki/controller-manager.key - - - - ${
          generators.kubernetes-controller-manager-crt.files."controller-manager.key".path
        }"

        # Scheduler certificate
        "L+ /var/lib/kubernetes/pki/scheduler.crt - - - - ${
          generators.kubernetes-scheduler-crt.files."scheduler.crt".path
        }"
        "L+ /var/lib/kubernetes/pki/scheduler.key - - - - ${
          generators.kubernetes-scheduler-crt.files."scheduler.key".path
        }"

        # Service account keys
        "L+ /var/lib/kubernetes/pki/sa.key - - - - ${
          generators.kubernetes-service-account-keys.files."sa.key".path
        }"
        "L+ /var/lib/kubernetes/pki/sa.pub - - - - ${
          generators.kubernetes-service-account-keys.files."sa.pub".path
        }"

        # etcd certificates
        "L+ /var/lib/kubernetes/pki/etcd/server.crt - - - - ${
          generators.etcd-server-crt.files."etcd-server.crt".path
        }"
        "L+ /var/lib/kubernetes/pki/etcd/server.key - - - - ${
          generators.etcd-server-crt.files."etcd-server.key".path
        }"
        "L+ /var/lib/kubernetes/pki/etcd/peer.crt - - - - ${
          generators.etcd-peer-crt.files."etcd-peer.crt".path
        }"
        "L+ /var/lib/kubernetes/pki/etcd/peer.key - - - - ${
          generators.etcd-peer-crt.files."etcd-peer.key".path
        }"
        "L+ /var/lib/kubernetes/pki/etcd/healthcheck-client.crt - - - - ${
          generators.etcd-healthcheck-client-crt.files."etcd-healthcheck-client.crt".path
        }"
        "L+ /var/lib/kubernetes/pki/etcd/healthcheck-client.key - - - - ${
          generators.etcd-healthcheck-client-crt.files."etcd-healthcheck-client.key".path
        }"

        # Kubelet certificates (for control-plane nodes that also run kubelet)
        "L+ /var/lib/kubelet/ca.crt - - - - ${generators.kubernetes-ca-crt.files."ca.crt".path}"
        "L+ /var/lib/kubelet/kubelet-server.crt - - - - ${
          generators.kubernetes-kubelet-server-crt.files."kubelet-server.crt".path
        }"
        "L+ /var/lib/kubelet/kubelet-server.key - - - - ${
          generators.kubernetes-kubelet-server-crt.files."kubelet-server.key".path
        }"
        "L+ /var/lib/kubelet/kubelet-client.crt - - - - ${
          generators.kubernetes-kubelet-client-crt.files."kubelet-client.crt".path
        }"
        "L+ /var/lib/kubelet/kubelet-client.key - - - - ${
          generators.kubernetes-kubelet-client-crt.files."kubelet-client.key".path
        }"
      ];
    };

  flake.modules.nixos.kubernetes-compute =
    { pkgs, config, ... }:
    let
      hostname = config.networking.hostName;
      nodeIp = config.nut.kubernetes.nodeIP;
      generators = config.clan.core.vars.generators;

      # Helper function to generate a certificate signed by kubernetes CA
      mkK8sCertificate =
        {
          name,
          commonName,
          orgs ? [ ],
          extKeyUsage ? [ "clientAuth" ],
          sans ? [ ],
          keyOwner ? "kubernetes",
          keyGroup ? "kubernetes",
          share ? false,
        }:
        {
          inherit share;
          files."${name}.key" = {
            secret = true;
            owner = keyOwner;
            group = keyGroup;
            mode = "0440";
          };
          files."${name}.crt" = {
            secret = false;
          };

          dependencies = [ "kubernetes-ca-crt" ];
          runtimeInputs = [ pkgs.step-cli ];
          script = ''
            cat > ${name}.tpl <<EOF
            {
              "subject": {
                "commonName": "${commonName}"${
                  if orgs != [ ] then ",\n                  \"organization\": ${builtins.toJSON orgs}" else ""
                }
              },
              "keyUsage": ["digitalSignature", "keyEncipherment"],
              "basicConstraints": { "isCA": false },
              "extKeyUsage": ${builtins.toJSON extKeyUsage}${
                if sans != [ ] then ",\n              \"sans\": {{ toJson .SANs }}" else ""
              }
            }
            EOF

            step certificate create ${name} $out/${name}.crt $out/${name}.key \
            --template ${name}.tpl \
            --ca $in/kubernetes-ca-crt/ca.crt \
            --ca-key $in/kubernetes-ca-crt/ca.key \
            --no-password --insecure \
            --not-after 8760h \
            ${builtins.concatStringsSep " " (map (san: "--san ${san}") sans)}
          '';
        };
    in
    {
      clan.core.vars.generators = {
        # Kubelet server certificate (per node)
        kubernetes-kubelet-server-crt = mkK8sCertificate {
          name = "kubelet-server";
          commonName = "system:node:${hostname}";
          orgs = [ "system:nodes" ];
          extKeyUsage = [ "serverAuth" ];
          sans = [
            hostname
            "127.0.0.1"
            "::1"
            "localhost"
            nodeIp
          ];
        };

        # Kubelet client certificate (per node)
        kubernetes-kubelet-client-crt = mkK8sCertificate {
          name = "kubelet-client";
          commonName = "system:node:${hostname}";
          orgs = [ "system:nodes" ];
          extKeyUsage = [ "clientAuth" ];
        };
      };

      systemd.tmpfiles.rules = [
        "d /var/lib/kubelet 0755 root root -"
        "L+ /var/lib/kubelet/ca.crt - - - - ${generators.kubernetes-ca-crt.files."ca.crt".path}"
        "L+ /var/lib/kubelet/kubelet-server.crt - - - - ${
          generators.kubernetes-kubelet-server-crt.files."kubelet-server.crt".path
        }"
        "L+ /var/lib/kubelet/kubelet-server.key - - - - ${
          generators.kubernetes-kubelet-server-crt.files."kubelet-server.key".path
        }"
        "L+ /var/lib/kubelet/kubelet-client.crt - - - - ${
          generators.kubernetes-kubelet-client-crt.files."kubelet-client.crt".path
        }"
        "L+ /var/lib/kubelet/kubelet-client.key - - - - ${
          generators.kubernetes-kubelet-client-crt.files."kubelet-client.key".path
        }"
      ];
    };
}
