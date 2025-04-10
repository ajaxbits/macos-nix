{ user, ... }:
{
  homebrew = {
    enable = true;
    onActivation.cleanup = "zap";
    onActivation.upgrade = true;
    brews = [
      "cabextract"
    ];
    casks = [
      "ankerwork"
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
      "podman-desktop"
      "prismlauncher"
      "rocket"
      "tailscale"
      "talon"
      "tor-browser"
      "visual-studio-code"
      "vlc"
      "wine@devel"
    ];
    caskArgs.appdir = "/Users/${user}/Applications";
  };
}
