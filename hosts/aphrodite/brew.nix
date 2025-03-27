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
      "discord"
      "eloston-chromium"
      "fantastical"
      "firefox"
      "flycut"
      "homerow"
      "jordanbaird-ice"
      "keepingyouawake"
      "rocket"
      "tailscale"
      "talon"
      "tor-browser"
      "visual-studio-code"
      "vlc"
    ];
    caskArgs.appdir = "/Users/${user}/Applications";
  };
}
