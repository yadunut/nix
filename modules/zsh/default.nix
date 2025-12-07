{ ... }:
{
  flake.modules.darwin.base =
    { ... }:
    {
      programs.zsh.enable = true;
    };
  flake.modules.nixos.base =
    { ... }:
    {
      programs.zsh.enable = true;
    };
  flake.modules.homeManager.base =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        zsh-completions
        fd
        ripgrep
        wget
        delta
      ];

      programs = {
        bat = {
          enable = true;
        };
        dircolors = {
          enable = true;
          enableZshIntegration = true;
        };
        direnv = {
          enable = true;
          enableZshIntegration = true;
          nix-direnv.enable = true;
          config = {
            hide_env_diff = true;
          };
          package = pkgs.direnv.overrideAttrs (old: {
            doCheck = false;
          });
        };
        zsh = {
          defaultKeymap = "viins";
          enable = true;
          enableCompletion = true;
          syntaxHighlighting.enable = true;
          autosuggestion.enable = true;
          autocd = true;
          history = {
            size = 1000000;
            extended = true;
            append = true;
            expireDuplicatesFirst = true;
            ignoreDups = true;
            ignoreAllDups = true;
            ignoreSpace = true;
          };
          historySubstringSearch.enable = true;
          shellAliases = {
            cat = "bat --theme=\"$(defaults read -globalDomain AppleInterfaceStyle &> /dev/null && echo 'gruvbox-dark' || echo 'gruvbox-light')\"";
            diff = "delta";
          };
          profileExtra = builtins.readFile ./functions.zsh;
        };
        fzf = {
          enable = true;
          enableZshIntegration = true;
        };
        zoxide = {
          enable = true;
          enableZshIntegration = true;
        };
        eza = {
          enable = true;
          enableZshIntegration = true;
          extraOptions = [ "--group-directories-first" ];
        };
        starship = {
          enable = true;
          enableZshIntegration = true;
          settings = {
            nodejs.disabled = true;
            package.disabled = true;
            aws.disabled = true;
            python.disabled = true;
          };
        };
        nix-your-shell = {
          enable = true;
          enableZshIntegration = true;
        };
        atuin = {
          enable = true;
          enableZshIntegration = true;
        };
      };

    };
}
