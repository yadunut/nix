{
  flake.modules.nixos.kubernetes-common =
    { pkgs, config, ... }:
    let
      clusterName = config.nut.kubernetes.instanceName;
      generators = config.clan.core.vars.generators;
    in
    {
      clan.core.vars.generators = {
        # Admin kubeconfig for kubectl (shared across all nodes for convenience)
        kubernetes-admin-kubeconfig = {
          share = true;
          files."admin.kubeconfig" = {
            secret = true;
            owner = "kubernetes";
            group = "kubernetes";
            mode = "0440";
          };
          dependencies = [
            "kubernetes-ca-crt"
            "kubernetes-admin-crt"
          ];
          runtimeInputs = [ pkgs.kubectl ];
          script = ''
            kubectl config set-cluster ${clusterName} \
              --certificate-authority=$in/kubernetes-ca-crt/ca.crt \
              --embed-certs=true \
              --server=https://127.0.0.1:6443 \
              --kubeconfig=$out/admin.kubeconfig

            kubectl config set-credentials kubernetes-admin \
              --client-certificate=$in/kubernetes-admin-crt/admin.crt \
              --client-key=$in/kubernetes-admin-crt/admin.key \
              --embed-certs=true \
              --kubeconfig=$out/admin.kubeconfig

            kubectl config set-context default \
              --cluster=${clusterName} \
              --user=kubernetes-admin \
              --kubeconfig=$out/admin.kubeconfig

            kubectl config use-context default \
              --kubeconfig=$out/admin.kubeconfig
          '';
        };
      };

      # Symlink admin kubeconfig to standard locations for kubectl
      systemd.tmpfiles.rules = [
        "d /root/.kube 0755 root root -"
        "L+ /root/.kube/config - - - - ${
          generators.kubernetes-admin-kubeconfig.files."admin.kubeconfig".path
        }"
        "d /home/yadunut/.kube 0755 yadunut users -"
        "L+ /home/yadunut/.kube/config - - - - ${
          generators.kubernetes-admin-kubeconfig.files."admin.kubeconfig".path
        }"
      ];
    };
}
