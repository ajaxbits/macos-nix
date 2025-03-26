{ user, ... }:
{
  homebrew = {
    enable = true;
    onActivation.cleanup = "zap";
    onActivation.upgrade = true;
    taps = [
      "homebrew/bundle"
      "homebrew/cask-versions"
    ];
    casks = [
      "ankerwork"
      "betterdisplay"
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
      "visual-studio-code"
      "vlc"
    ];
    caskArgs.appdir = "/Users/${user}/Applications";
  };
}
