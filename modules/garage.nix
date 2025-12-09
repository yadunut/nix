{
  flake.modules.nixos.garage =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.nut.garage;
      defaultDataDir = "/var/lib/garage/data";
      defaultMetadataDir = "/var/lib/garage/meta";
    in
    {
      options.nut.garage = {
        dataDir = lib.mkOption {
          type = lib.types.str;
          default = defaultDataDir;
        };
        metadataDir = lib.mkOption {
          type = lib.types.str;
          default = defaultMetadataDir;
        };
        publicAddrSubnet = lib.mkOption {
          type = lib.types.str;
        };
      };
      config = lib.mkMerge [
        {
          services.garage = {
            package = pkgs.garage_2;
            enable = true;
            settings = {
              allow_world_readable_secrets = true;
              metadata_dir = cfg.metadataDir;
              data_dir = cfg.dataDir;
              db_engine = "sqlite";

              replication_factor = 1;
              rpc_bind_addr = "[::]:3901";
              rpc_public_addr_subnet = cfg.publicAddrSubnet;

              s3_api = {
                s3_region = "garage";
                api_bind_addr = "[::]:3900";
                root_domain = ".s3.garage.yadunut.com";
              };

              s3_web = {
                bind_addr = "[::]:3902";
                root_domain = ".web.garage.yadunut.com";
                index = "index.html";
              };

              k2v_api = {
                api_bind_addr = "[::]:3904";
              };

              admin = {
                api_bind_addr = "[::]:3903";
              };
            };
          };
          users.groups.garage-data = { };
          users.users.yadunut.extraGroups = [ "garage-data" ];
          systemd.services.garage = {
            serviceConfig = {
              SupplementaryGroups = [ "garage-data" ];
              LoadCredential = [
                "rpc_secret_path:${config.clan.core.vars.generators.garage-shared.files.rpc_secret.path}"
                "admin_token_path:${config.clan.core.vars.generators.garage.files.admin_token.path}"
                "metrics_token_path:${config.clan.core.vars.generators.garage.files.metrics_token.path}"
              ];
              Environment = [
                "GARAGE_RPC_SECRET_FILE=%d/rpc_secret_path"
                "GARAGE_ADMIN_TOKEN_FILE=%d/admin_token_path"
                "GARAGE_METRICS_TOKEN_FILE=%d/metrics_token_path"
              ];
            };
          };
          clan.core.vars.generators.garage-shared = {
            share = true;
            files."rpc_secret" = { };
            runtimeInputs = [ pkgs.openssl ];
            script = ''
              openssl rand -hex 32 > $out/rpc_secret
            '';
          };
          clan.core.vars.generators.garage = {
            files."admin_token" = { };
            files."metrics_token" = { };
            runtimeInputs = [ pkgs.openssl ];
            script = ''
              openssl rand -base64 32 > $out/admin_token
              openssl rand -base64 32 > $out/metrics_token
            '';
          };
        }
        (lib.mkIf (cfg.dataDir != defaultDataDir || cfg.metadataDir != defaultMetadataDir) {
          users.groups.garage-data = { };
          systemd.services.garage.serviceConfig = {
            SupplementaryGroups = [ "garage-data" ];
          };
          users.users.yadunut.extraGroups = [ "garage-data" ];
        })
        (lib.mkIf (cfg.dataDir != defaultDataDir) {
          systemd.tmpfiles.rules =
            let
              rootDataDir = builtins.dirOf cfg.dataDir;
            in
            [
              "d ${rootDataDir} 0755 root root -"
              "d ${cfg.dataDir} 0770 root garage-data -"
            ];
        })
        (lib.mkIf (cfg.metadataDir != defaultMetadataDir) {
          systemd.tmpfiles.rules =
            let
              rootMetaDir = builtins.dirOf cfg.metadataDir;
            in
            [
              "d ${rootMetaDir} 0755 root root -"
              "d ${cfg.metadataDir} 0770 root garage-data -"
            ];
        })
      ];
    };
}
