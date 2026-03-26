# User identity, shared across darwin and home-manager
let
  userName = "ajax";
  fullName = "Alex Jackson";
in
{
  flake.modules.darwin.user =
    { pkgs, ... }:
    {
      system.primaryUser = userName;
      nix.settings.trusted-users = [ userName ];

      programs.zsh.enable = true;
      programs.fish.enable = true;

      users.knownUsers = [ userName ];
      users.users.${userName} = {
        description = fullName;
        home = "/Users/${userName}";
        shell = pkgs.fish;
        uid = 501;
      };

      environment.variables = {
        EDITOR = "nvim";
        SSH_AUTH_SOCK = "/Users/${userName}/.bitwarden-ssh-agent.sock";
      };
    };

  flake.modules.homeManager.user =
    { pkgs, lib, ... }:
    {
      home = {
        username = lib.mkDefault userName;
        homeDirectory = lib.mkDefault "/Users/${userName}";
        stateVersion = lib.mkDefault "22.05";
      };
    };
}
