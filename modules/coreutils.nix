# The basic utils I always need
{ inputs, ... }:
{
  flake.modules.darwin.coreutils =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        curl
        dust
        fd
        git
        hck
        ripgrep
        sd
        uv
        viddy

        inputs.nvim.packages.${pkgs.system}.default
      ];
    };

  flake.modules.homeManager.coreutils =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        bat
        entr
        fx
        gh
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
        fzf = {
          enable = true;
          enableFishIntegration = true;
          enableBashIntegration = true;
          colors = {
            bg = "#282828";
            "bg+" = "#3c3836";
            fg = "#ebdbb2";
            "fg+" = "#d4d4d4";
            hl = "#fabd2f";
            "hl+" = "#fabd2f";

            info = "#83a598";
            prompt = "#bdae93";
            spinner = "#fabd2f";
            pointer = "#83a598";
            marker = "#fe8019";
            header = "#665c54";
          };

          fileWidgetCommand = "fd --type f";
        };
      };
    };
}
