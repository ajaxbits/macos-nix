# Homebrew policy and casks (darwin only)
{
  flake.aspects = {
    brew-base.darwin =
      { config, ... }:
      {
        homebrew = {
          enable = true;
          onActivation.upgrade = true;
          casks = [
            "ankerwork"
            "balenaetcher"
            "betterdisplay"
            "fantastical"
            "helium-browser"
            "hiddenbar"
            "jordanbaird-ice"
            "keepingyouawake"
            "maccy"
            "roam-research"
            "rocket"
            "shottr"
            "tailscale-app"
            "vlc"
          ];
          caskArgs.appdir = "${config.macosNix.host.homeDirectory}/Applications";
        };
      };

    brew-personal.darwin.homebrew = {
      onActivation.cleanup = "zap";
      casks = [
        "bitwarden"
        "discord"
        "notesnook"
        "passepartout"
        "podman-desktop"
        "prismlauncher"
        "raspberry-pi-imager"
        "steam"
      ];
    };

    brew-work.darwin.homebrew = {
      onActivation.cleanup = "none";
      # hex's flake is x86_64-linux only; macOS ships via this tap.
      taps = [ "anomalyco/tap" ];
      casks = [
        "anomalyco/tap/hex"
        "logseq"
        "yojam"
        "zoom"
      ];
    };
  };
}
