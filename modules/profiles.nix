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
      opencode
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
    ];
  };

  flake.modules.homeManager.personal = {
    imports = with config.flake.modules.homeManager; [
      foundation
      coreutils-personal
      opencode
    ];
  };

  flake.modules.homeManager.work = {
    imports = with config.flake.modules.homeManager; [
      foundation
    ];
  };
}
