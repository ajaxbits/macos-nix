# Explicit feature composition for each profile.
{
  flake.aspects =
    { aspects, ... }:
    {
      foundation = {
        includes = with aspects; [
          ai-base
          aerospace-base
          brew-base
          coreutils
          fish
          host
          macos-defaults
          nix
          paneru-base
          secretive
          secrets
          shared-secrets
          terminal
          user
          vcs
          yazi
        ];
      };

      personal = {
        includes = with aspects; [
          ai-personal
          aerospace-personal
          brew-personal
          coreutils-personal
          ebooks-personal
          foundation
          firefox-personal
          podman-personal
        ];
      };

      work = {
        includes = with aspects; [
          aerospace-work
          ai-work
          aws-work
          brew-work
          firefox-work
          foundation
          work-shell-secrets
        ];

        homeManager =
          { config, pkgs, ... }:
          {
            home.packages = [ pkgs.poetry ];
            home.sessionPath = [ "${config.home.homeDirectory}/.local/bin" ];
          };
      };
    };
}
