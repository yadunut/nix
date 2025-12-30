{
  flake.modules.nixos.kubernetes-controller =
    {
      pkgs,
      config,
      ...
    }:
    let
      generators = config.clan.core.vars.generators;
      clusterName = config.nut.kubernetes.instanceName;
      clusterCIDR = config.nut.kubernetes.clusterCIDR;
      clusterDomain = config.nut.kubernetes.domain;
      serviceCIDR = config.nut.kubernetes.serviceCIDR;
      nodeIP = config.nut.kubernetes.nodeIP;
      etcdEndpoints = config.nut.kubernetes.etcd.endpoints;
    in
    {
      environment.systemPackages = [ pkgs.kubernetes ];

      # Generate kubeconfig files for scheduler and controller-manager
      clan.core.vars.generators = {
        kubernetes-scheduler-kubeconfig = {
          share = false;
          files."kube-scheduler.kubeconfig" = {
            secret = true;
            owner = "kubernetes";
            group = "kubernetes";
            mode = "0440";
          };
          dependencies = [
            "kubernetes-ca-crt"
            "kubernetes-scheduler-crt"
          ];
          runtimeInputs = [ pkgs.kubectl ];
          script = ''
            kubectl config set-cluster ${clusterName} \
              --certificate-authority=$in/kubernetes-ca-crt/ca.crt \
              --embed-certs=true \
              --server=https://[${nodeIP}]:6443 \
              --kubeconfig=$out/kube-scheduler.kubeconfig

            kubectl config set-credentials system:kube-scheduler \
              --client-certificate=$in/kubernetes-scheduler-crt/scheduler.crt \
              --client-key=$in/kubernetes-scheduler-crt/scheduler.key \
              --embed-certs=true \
              --kubeconfig=$out/kube-scheduler.kubeconfig

            kubectl config set-context default \
              --cluster=${clusterName} \
              --user=system:kube-scheduler \
              --kubeconfig=$out/kube-scheduler.kubeconfig

            kubectl config use-context default \
              --kubeconfig=$out/kube-scheduler.kubeconfig
          '';
        };

        kubernetes-controller-manager-kubeconfig = {
          share = false;
          files."kube-controller-manager.kubeconfig" = {
            secret = true;
            owner = "kubernetes";
            group = "kubernetes";
            mode = "0440";
          };
          dependencies = [
            "kubernetes-ca-crt"
            "kubernetes-controller-manager-crt"
          ];
          runtimeInputs = [ pkgs.kubectl ];
          script = ''
            kubectl config set-cluster ${clusterName} \
              --certificate-authority=$in/kubernetes-ca-crt/ca.crt \
              --embed-certs=true \
              --server=https://[${nodeIP}]:6443 \
              --kubeconfig=$out/kube-controller-manager.kubeconfig

            kubectl config set-credentials system:kube-controller-manager \
              --client-certificate=$in/kubernetes-controller-manager-crt/controller-manager.crt \
              --client-key=$in/kubernetes-controller-manager-crt/controller-manager.key \
              --embed-certs=true \
              --kubeconfig=$out/kube-controller-manager.kubeconfig

            kubectl config set-context default \
              --cluster=${clusterName} \
              --user=system:kube-controller-manager \
              --kubeconfig=$out/kube-controller-manager.kubeconfig

            kubectl config use-context default \
              --kubeconfig=$out/kube-controller-manager.kubeconfig
          '';
        };
      };

      # Symlink kubeconfig files to standard location
      systemd.tmpfiles.rules = [
        "L+ /var/lib/kubernetes/kube-scheduler.kubeconfig - - - - ${
          generators.kubernetes-scheduler-kubeconfig.files."kube-scheduler.kubeconfig".path
        }"
        "L+ /var/lib/kubernetes/kube-controller-manager.kubeconfig - - - - ${
          generators.kubernetes-controller-manager-kubeconfig.files."kube-controller-manager.kubeconfig".path
        }"
        "L+ /var/lib/kubernetes/encryption-config.yaml - - - - ${
          generators.kubernetes-encryption-config.files."encryption-config.yaml".path
        }"
      ];

      systemd.services."kube-apiserver" = {
        description = "Kubernetes API Server";
        documentation = [ "https://github.com/kubernetes/kubernetes" ];
        wantedBy = [ "kubernetes.target" ];
        after = [
          "network.target"
          "etcd.service"
          "systemd-tmpfiles-setup.service"
        ];
        requires = [ "etcd.service" ];

        serviceConfig = {
          ExecStart = ''
            ${pkgs.kubernetes}/bin/kube-apiserver \
              --allow-privileged=true \
              --audit-log-path=- \
              --authorization-mode=Node,RBAC \
              --bind-address=:: \
              --advertise-address=${nodeIP} \
              --client-ca-file=/var/lib/kubernetes/pki/ca.crt \
              --enable-admission-plugins=NamespaceLifecycle,NodeRestriction,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota,DefaultTolerationSeconds \
              --etcd-servers=${etcdEndpoints} \
              --etcd-cafile=/var/lib/kubernetes/pki/etcd/ca.crt \
              --etcd-certfile=/var/lib/kubernetes/pki/apiserver-etcd-client.crt \
              --etcd-keyfile=/var/lib/kubernetes/pki/apiserver-etcd-client.key \
              --event-ttl=1h \
              --encryption-provider-config=/var/lib/kubernetes/encryption-config.yaml \
              --kubelet-certificate-authority=/var/lib/kubernetes/pki/ca.crt \
              --kubelet-client-certificate=/var/lib/kubernetes/pki/apiserver-kubelet-client.crt \
              --kubelet-client-key=/var/lib/kubernetes/pki/apiserver-kubelet-client.key \
              --runtime-config=api/all=true \
              --service-account-key-file=/var/lib/kubernetes/pki/sa.pub \
              --service-account-signing-key-file=/var/lib/kubernetes/pki/sa.key \
              --service-account-issuer=https://kubernetes.default.svc.${clusterDomain} \
              --service-cluster-ip-range=${serviceCIDR} \
              --service-node-port-range=30000-32767 \
              --tls-cert-file=/var/lib/kubernetes/pki/apiserver.crt \
              --tls-private-key-file=/var/lib/kubernetes/pki/apiserver.key \
              --v=2
          '';
          Restart = "on-failure";
          RestartSec = 5;
          User = "kubernetes";
          Group = "kubernetes";
        };
      };

      environment.etc."kubernetes/config/kube-scheduler.yaml".text = ''
        apiVersion: kubescheduler.config.k8s.io/v1
        kind: KubeSchedulerConfiguration
        clientConnection:
          kubeconfig: "/var/lib/kubernetes/kube-scheduler.kubeconfig"
        leaderElection:
          leaderElect: true
      '';

      systemd.services."kube-scheduler" = {
        description = "Kubernetes Scheduler";
        documentation = [ "https://github.com/kubernetes/kubernetes" ];
        wantedBy = [ "kubernetes.target" ];
        after = [
          "kube-apiserver.service"
          "systemd-tmpfiles-setup.service"
        ];
        requires = [ "kube-apiserver.service" ];

        serviceConfig = {
          ExecStart = ''
            ${pkgs.kubernetes}/bin/kube-scheduler \
              --config=/etc/kubernetes/config/kube-scheduler.yaml \
              --v=2
          '';
          Restart = "on-failure";
          RestartSec = 5;
          User = "kubernetes";
          Group = "kubernetes";
        };
      };

      systemd.services."kube-controller-manager" = {
        description = "Kubernetes Controller Manager";
        documentation = [ "https://github.com/kubernetes/kubernetes" ];
        wantedBy = [ "kubernetes.target" ];
        after = [
          "kube-apiserver.service"
          "systemd-tmpfiles-setup.service"
        ];
        requires = [ "kube-apiserver.service" ];

        serviceConfig = {
          ExecStart = ''
            ${pkgs.kubernetes}/bin/kube-controller-manager \
              --allocate-node-cidrs=true \
              --bind-address=:: \
              --cluster-cidr=${clusterCIDR} \
              --cluster-name=${clusterName} \
              --cluster-signing-cert-file=/var/lib/kubernetes/pki/ca.crt \
              --cluster-signing-key-file=/var/lib/kubernetes/pki/ca.key \
              --kubeconfig=/var/lib/kubernetes/kube-controller-manager.kubeconfig \
              --root-ca-file=/var/lib/kubernetes/pki/ca.crt \
              --service-account-private-key-file=/var/lib/kubernetes/pki/sa.key \
              --service-cluster-ip-range=${serviceCIDR} \
              --use-service-account-credentials=true \
              --v=2
          '';
          Restart = "on-failure";
          RestartSec = 5;
          User = "kubernetes";
          Group = "kubernetes";
        };
      };
    };
}
