{
  flake.modules.darwin.macos-defaults =
    { config, lib, ... }:
    let
      inherit (config.macosNix) host;
      wallpaper = ../assets/lava-dark.jpg;
      wallpaperScript = ''
        tell application "System Events"
          tell every desktop
            set picture to POSIX file "${wallpaper}"
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
            # Reserve three-finger gestures for Paneru's direct strip navigation.
            TrackpadThreeFingerDrag = false;
          };
          NSGlobalDomain = {
            "com.apple.sound.beep.feedback" = 0;
            AppleInterfaceStyle = "Dark";
          };
        };
        keyboard.enableKeyMapping = true;
        keyboard.remapCapsLockToEscape = true;
        # nix-darwin only runs the fixed set of activation scripts it assembles,
        # so this must hook into postActivation to run at all. Activation runs as
        # root, and the picture belongs to the user's GUI session.
        activationScripts.postActivation.text = ''
          wallpaperUser=${lib.escapeShellArg host.userName}
          if ! launchctl asuser "$(id -u -- "$wallpaperUser")" \
            sudo --user="$wallpaperUser" -- \
            /usr/bin/osascript -e ${lib.escapeShellArg wallpaperScript}; then
            printf >&2 'warning: could not set the desktop wallpaper for %s\n' "$wallpaperUser"
          fi
        '';
      };

      security.pam.services.sudo_local.touchIdAuth = true;
    };
}
