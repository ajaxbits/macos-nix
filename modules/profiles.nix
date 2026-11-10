# Explicit feature composition for each profile.
{ inputs, ... }:
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
          ssh
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
          linear-work
          work-shell-secrets
        ];

        homeManager =
          { config, pkgs, ... }:
          {
            home.packages = [
              pkgs.poetry
              inputs.neorex.packages.${pkgs.stdenv.hostPlatform.system}.default
            ];
            home.sessionPath = [ "${config.home.homeDirectory}/.local/bin" ];
          };
      };
    };
}
