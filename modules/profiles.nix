# Explicit feature composition for each profile.
{ config, ... }:
{
  flake.modules.darwin.foundation = {
    imports = with config.flake.modules.darwin; [
      host
      user
      nix
      macos-defaults
      brew
      coreutils
      aerospace
      terminal
      opencode
      secretive
      secrets
    ];
  };

  flake.modules.darwin.personal = {
    imports = with config.flake.modules.darwin; [
      foundation
      brew-personal
      ebooks
      podman
    ];
  };

  # This profile is intentionally not deployable until real work host facts and
  # the remaining work features are added.
  flake.modules.darwin.work = {
    imports = with config.flake.modules.darwin; [
      foundation
    ];
  };

  flake.modules.homeManager.foundation = {
    imports = with config.flake.modules.homeManager; [
      host
      user
      coreutils
      fish
      terminal
      vcs
      secrets
      shared-secrets
      opencode
    ];
  };

  flake.modules.homeManager.personal = {
    imports = with config.flake.modules.homeManager; [
      foundation
      firefox-personal
      coreutils-personal
    ];
  };

  flake.modules.homeManager.work = {
    imports = with config.flake.modules.homeManager; [
      foundation
      firefox-work
    ];
  };
}
