# Explicit feature composition for each profile.
{ config, ... }:
{
  flake.modules = {
    darwin = {
      foundation = {
        imports = with config.flake.modules.darwin; [
          ai-base
          aerospace-base
          brew-base
          coreutils
          host
          macos-defaults
          nix
          secretive
          secrets
          terminal
          user
        ];
      };

      personal = {
        imports = with config.flake.modules.darwin; [
          aerospace-personal
          brew-personal
          ebooks-personal
          foundation
          podman-personal
        ];
      };

      work = {
        imports = with config.flake.modules.darwin; [
          aerospace-work
          ai-work
          brew-work
          foundation
        ];
      };
    };

    homeManager = {
      foundation = {
        imports = with config.flake.modules.homeManager; [
          ai-base
          coreutils
          fish
          host
          secrets
          shared-secrets
          terminal
          user
          yazi
          vcs
        ];
      };

      personal = {
        imports = with config.flake.modules.homeManager; [
          ai-personal
          coreutils-personal
          firefox-personal
          foundation
        ];
      };

      work = {
        imports = with config.flake.modules.homeManager; [
          ai-work
          coreutils-work
          firefox-work
          foundation
        ];
      };
    };
  };
}
