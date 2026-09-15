# Homebrew policy and casks (darwin only)
{
  flake.modules.darwin = {
    brew-base =
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

    brew-personal.homebrew = {
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

    brew-work.homebrew = {
      onActivation.cleanup = "none";
      casks = [
        "logseq"
        "yojam"
        "zoom"
      ];
    };
  };
}
