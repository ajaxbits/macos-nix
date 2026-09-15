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
            "betterdisplay"
            "fantastical"
            "helium-browser"
            "hiddenbar"
            "jordanbaird-ice"
            "keepingyouawake"
            "maccy"
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
        "balenaetcher"
        "bitwarden"
        "discord"
        "notesnook"
        "passepartout"
        "podman-desktop"
        "prismlauncher"
        "raspberry-pi-imager"
        "roam-research"
        "steam"
      ];
    };

    brew-work.darwin.homebrew = {
      onActivation.cleanup = "none";
      casks = [
        "logseq"
        "yojam"
        "zoom"
      ];
    };
  };
}
