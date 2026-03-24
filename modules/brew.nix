# Homebrew casks (darwin only)
{ ... }:
let
  userName = "ajax";
in
{
  flake.modules.darwin.brew = {
    homebrew = {
      enable = true;
      onActivation.cleanup = "zap";
      onActivation.upgrade = true;
      casks = [
        "ankerwork"
        "balenaetcher"
        "betterdisplay"
        "bitwarden"
        "discord"
        "fantastical"
        "firefox"
        "helium-browser"
        "homerow"
        "jordanbaird-ice"
        "keepingyouawake"
        "maccy"
        "notesnook"
        "passepartout"
        "podman-desktop"
        "prismlauncher"
        "raspberry-pi-imager"
        "roam-research"
        "rocket"
        "shottr"
        "steam"
        "tailscale-app"
        "talon"
        "tor-browser"
        "visual-studio-code"
        "vlc"
      ];
      caskArgs.appdir = "/Users/${userName}/Applications";
    };
  };
}
