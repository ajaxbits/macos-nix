# System and user packages
{ inputs, ... }:
{
  flake.modules.darwin.packages =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        dust
        eza
        fd
        hck
        ripgrep
        sd
        uv
        viddy

        inputs.nvim.packages.${pkgs.system}.default
      ];
    };

  flake.modules.homeManager.packages =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        anki-bin
        attic-client
        bat
        coreutils
        curl
        entr
        fx
        gh
        git
        jujutsu
        nix-output-monitor
        seventeenlands
        xh
        zoxide
      ];

      programs = {
        atuin = {
          enable = true;
          enableBashIntegration = true;
          enableFishIntegration = true;
        };
        direnv = {
          enable = true;
          nix-direnv.enable = true;
          enableBashIntegration = true;
        };
        eza.enable = true;
        jq.enable = true;
        lazygit.enable = true;
      };
    };
}
