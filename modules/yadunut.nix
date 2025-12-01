{ hosts, ... }:
{
  flake.modules.darwin.base =
    { pkgs, ... }:
    {
      system.primaryUser = "yadunut";
      users.users.yadunut = {
        home = "/Users/yadunut";
        shell = pkgs.zsh;
        openssh.authorizedKeys.keys = [ hosts.user.yadunut ];
      };
      users.users.root = {
        shell = pkgs.zsh;
        openssh.authorizedKeys.keys = [ hosts.user.yadunut ];
      };
    };
  flake.modules.nixos.base =
    { pkgs, ... }:
    {
      users.users.yadunut = {
        shell = pkgs.zsh;
        openssh.authorizedKeys.keys = [ hosts.user.yadunut ];
        isNormalUser = true;
        hashedPassword = "$y$j9T$XR5JhClixWp8d626AsjPZ.$PdN77P4SRt/GuJ9jVovcTSOh6ySf9alSsflFJG8n2A.";
        extraGroups = [ "wheel" ];
      };
      users.users.root = {
        shell = pkgs.zsh;
        openssh.authorizedKeys.keys = [ hosts.user.yadunut ];
        hashedPassword = "$y$j9T$XR5JhClixWp8d626AsjPZ.$PdN77P4SRt/GuJ9jVovcTSOh6ySf9alSsflFJG8n2A.";
      };
    };

  flake.modules.homeManager.yadunut =
    { pkgs, ... }:
    {
      home.username = "yadunut";
      home.packages = with pkgs; [
        ouch
        rsync
        zellij
      ];
    };
}
