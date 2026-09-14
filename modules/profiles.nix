# Explicit feature composition for each profile.
{ config, ... }:
{
  flake.modules = {
    darwin = {
      foundation = {
        imports = with config.flake.modules.darwin; [
          aerospace-base
          brew-base
          coreutils
          host
          macos-defaults
          nix
          opencode
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
          brew-work
          foundation
        ];
      };
    };

    homeManager = {
      foundation = {
        imports = with config.flake.modules.homeManager; [
          coreutils
          fish
          host
          opencode
          secrets
          shared-secrets
          terminal
          user
          vcs
        ];
      };

      personal = {
        imports = with config.flake.modules.homeManager; [
          coreutils-personal
          firefox-personal
          foundation
        ];
      };

      work = {
        imports = with config.flake.modules.homeManager; [
          firefox-work
          foundation
        ];
      };
    };
  };
}
