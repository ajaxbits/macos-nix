{
  flake.modules.darwin.macos-defaults =
    { config, lib, ... }:
    let
      host = config.macosNix.host;
      wallpaper = ../assets/lava-dark.jpg;
      wallpaperScript = ''
        tell application "System Events"
          tell every desktop
            set picture to POSIX file ${builtins.toJSON (toString wallpaper)}
          end tell
        end tell
      '';
    in
    {
      system = {
        stateVersion = config.macosNix.host.darwinStateVersion;
        defaults = {
          finder = {
            AppleShowAllExtensions = true;
            QuitMenuItem = true;
            FXEnableExtensionChangeWarning = false;
          };
          dock = {
            autohide = true;
            orientation = "left";
          };
          screencapture.location = "/tmp";
          trackpad = {
            ActuationStrength = 0;
            Clicking = true;
            FirstClickThreshold = 0;
            TrackpadThreeFingerDrag = true;
          };
          NSGlobalDomain = {
            "com.apple.sound.beep.feedback" = 0;
            AppleInterfaceStyle = "Dark";
          };
        };
        keyboard.enableKeyMapping = true;
        keyboard.remapCapsLockToEscape = true;
        activationScripts.setWallpaper.text = ''
          user=${lib.escapeShellArg host.userName}
          uid="$(/usr/bin/id -u "$user")"
          /bin/launchctl asuser "$uid" /usr/bin/osascript -e ${lib.escapeShellArg wallpaperScript}
        '';
      };

      security.pam.services.sudo_local.touchIdAuth = true;
    };
}
