{
  flake.modules.nixos.kubernetes-controller =
    { pkgs, config, ... }:
    let
      generators = config.clan.core.vars.generators;
    in
    {
      clan.core.vars.generators = {
        kubernetes-encryption-config = {
          share = true;
          files."encryption-config.yaml" = {
            secret = true;
            owner = "kubernetes";
            group = "kubernetes";
            mode = "0440";
          };

          runtimeInputs = [
            pkgs.openssl
            pkgs.coreutils
          ];
          script = ''
            ENCRYPTION_KEY=$(openssl rand -base64 32)

            cat > $out/encryption-config.yaml <<EOF
            apiVersion: apiserver.config.k8s.io/v1
            kind: EncryptionConfiguration
            resources:
              - resources:
                  - secrets
                providers:
                  - aescbc:
                      keys:
                        - name: key1
                          secret: $ENCRYPTION_KEY
                  - identity: {}
            EOF
          '';
        };
      };

      # Symlink encryption config to standard location for kube-apiserver
      systemd.tmpfiles.rules = [
        "L+ /var/lib/kubernetes/encryption-config.yaml - - - - ${
          generators.kubernetes-encryption-config.files."encryption-config.yaml".path
        }"
      ];
    };
}
