# Homebrew policy and casks (darwin only)
{
  flake.modules.darwin.brew = { config, ... }: {
    homebrew = {
      enable = true;
      onActivation.cleanup = if config.macosNix.host.profile == "personal" then "zap" else "none";
      onActivation.upgrade = config.macosNix.host.profile == "personal";
      casks = [
        "ankerwork"
        "betterdisplay"
        "fantastical"
        "firefox"
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

  flake.modules.darwin.brew-personal = {
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
}
