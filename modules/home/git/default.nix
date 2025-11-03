{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nut.git;
  inherit (lib) mkEnableOption mkIf mkOption;
  types = lib.types;
  name = "Yadunand Prem";
  email = "yadunand@yadunut.com";
in
{
  options.nut.git = {
    enable = mkEnableOption "Git";
    gpgProgram = mkOption {
      default = null;
      type = types.nullOr types.str;
    };
    signingKey = mkOption {
      type = types.nullOr types.str;
      default = null;
    };
  };

  config = mkIf cfg.enable {

    home.packages = with pkgs; [
      git
      lazygit
      jujutsu
      delta
    ];

    programs.zsh.shellAliases = {
      lg = "lazygit";
      js = "jj status";
      jd = "jj diff";
      jn = "jj new";
      jf = "jj git fetch";
      jp = "jj git push";
    };
    programs.delta = {
      enable = true;
      enableGitIntegration = true;
    };
    programs.git = {
      ignores = [
        ".DS_Store"
        ".direnv/"
        ".envrc"
        "**/.claude/settings.local.json"
      ];
      enable = true;
      lfs.enable = true;

      settings = lib.mkMerge [
        {
          init = {
            defaultBranch = "main";
            defaultRefFormat = "files";
          };
          user = {
            email = email;
            name = name;
          };

          pull = {
            rebase = true;
            autostash = true;
          };
          push = {
            autoSetupRemote = true;
            followTags = true;
          };
          commit = {
            gpgsign = true;
            verbose = true;
          };
          diff = {
            # merge.conflictstyle = "zdiff2";
            colorMoved = true;
            algorithm = "histogram";
            mnemonicPrefix = true;
          };
          feature.experimental = true;
          branch.sort = "committerdate";
          fetch.all = true;
          column.ui = "auto";
          tags.sort = "version:refname";
          rerere = {
            enabled = true;
            autoupdate = true;
          };
          rebase = {
            autostash = true;
            autosquash = true;
            updateRefs = true;
          };
          credential = {
            helper = [
              "${pkgs.git-credential-oauth}/bin/git-credential-oauth"
            ];
            "https://git.yadunut.dev" = {
              oauthClientId = "a4792ccc-144e-407e-86c9-5e7d8d9c3269";
              oauthScopes = "read:repository write:repository";
              oauthAuthURL = "/login/oauth/authorize";
              oauthTokenURL = "/login/oauth/access_token";
            };
          };
          gpg.format = "ssh";
        }
        (mkIf (cfg.gpgProgram != null) { gpg.ssh.program = cfg.gpgProgram; })
        (mkIf (cfg.signingKey != null) { user.signingkey = "key::${cfg.signingKey}"; })
      ];
    };

    programs.jujutsu = {
      enable = true;
      settings = {
        user = {
          name = name;
          email = email;
        };
        aliases = {
          tug = [
            "bookmark"
            "move"
            "--from"
            "heads(::@- & bookmarks())"
            "--to"
            "@-"
          ];
        };
        ui.default-command = "log";
      };
    };
    programs.gh.enable = true;
  };
}
