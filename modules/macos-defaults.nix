# macOS system defaults: dock, finder, trackpad, keyboard
{ ... }:
{
  flake.modules.darwin.macos-defaults = {
    system = {
      stateVersion = 5;
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
    };

    security.pam.services.sudo_local.touchIdAuth = true;
  };
}
