{ user, ... }:
{
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
      "eloston-chromium"
      "fantastical"
      "firefox"
      "flycut"
      "homerow"
      "jordanbaird-ice"
      "keepingyouawake"
      "notesnook"
      "passepartout"
      "podman-desktop"
      "prismlauncher"
      "raspberry-pi-imager"
      "roam-research"
      "rocket"
      "shottr"
      "steam"
      "tailscale"
      "talon"
      "tor-browser"
      "visual-studio-code"
      "vlc"
    ];
    caskArgs.appdir = "/Users/${user}/Applications";
  };
}
