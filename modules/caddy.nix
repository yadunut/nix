{
  flake.modules.nixos.caddy =
    { pkgs, config, ... }:
    {
      clan.core.vars.generators.caddy = {
        prompts.caddy_env = {
          name = "caddy_env";
          description = "Caddy Env File";
          persist = true;
          type = "multiline-hidden";
        };
      };
      services.caddy = {
        enable = true;
        package = pkgs.caddy.withPlugins {
          plugins = [ "github.com/caddy-dns/cloudflare@v0.2.2" ];
          hash = "sha256-ea8PC/+SlPRdEVVF/I3c1CBprlVp1nrumKM5cMwJJ3U=";
        };
        virtualHosts = {
          "*.web.garage.yadunut.com".extraConfig = ''
            reverse_proxy :3902
            tls {
              dns cloudflare {
            		api_token {env.CF_API_TOKEN}
              }
            }
          '';
          "s3.garage.yadunut.com, *.s3.garage.yadunut.com".extraConfig = ''
            reverse_proxy :3900
            tls {
              dns cloudflare {
            		api_token {env.CF_API_TOKEN}
              }
            }
          '';
        };
      };
      systemd.services.caddy.serviceConfig.EnvironmentFile = [
        "${config.clan.core.vars.generators.caddy.files.caddy_env.path}"
      ];
    };
}
