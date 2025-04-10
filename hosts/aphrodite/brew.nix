{ user, ... }:
{
  homebrew = {
    enable = true;
    onActivation.cleanup = "zap";
    onActivation.upgrade = true;
    casks = [
      "ankerwork"
      "betterdisplay"
      "bitwarden"
      "cabextract"
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
      "wine"
      "winetricks"
    ];
    caskArgs.appdir = "/Users/${user}/Applications";
  };
}
