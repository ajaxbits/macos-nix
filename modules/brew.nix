# Homebrew policy and casks (darwin only)
{
  flake.modules.darwin = {
    brew-base =
      { config, ... }:
      {
        homebrew = {
          enable = true;
          casks = [
            "ankerwork"
            "betterdisplay"
            "fantastical"
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

    brew-personal = {
      homebrew.onActivation = {
        cleanup = "zap";
        upgrade = true;
      };
      homebrew.casks = [
        "balenaetcher"
        "bitwarden"
        "discord"
        "helium-browser"
        "notesnook"
        "passepartout"
        "podman-desktop"
        "prismlauncher"
        "raspberry-pi-imager"
        "roam-research"
        "steam"
      ];
    };

    brew-work = {
      homebrew.onActivation = {
        cleanup = "none";
        upgrade = false;
      };
    };
  };
}
