# The basic utils I always need
{ inputs, ... }:
{
  flake.aspects = {
    coreutils = {
      darwin =
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
      homeManager =
        { pkgs, lib, ... }:
        {
          home.packages = with pkgs; [
            bat
            entr
            fx
            gh
            jujutsu
            nix-output-monitor
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

              fileWidget.command = "${lib.getExe pkgs.fd} --type f";
              historyWidget.command = "";
            };
          };
        };
    };

    coreutils-personal.homeManager =
        { pkgs, ... }:
        {
          home.packages = [ pkgs.seventeenlands ];
        };

    coreutils-work.homeManager =
        { pkgs, ... }:
        {
          home.packages = [ pkgs.awscli2 ];
        };
  };
}
