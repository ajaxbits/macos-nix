{ inputs, ... }:
{
  flake.aspects.paneru-base.homeManager = {
    # macOS also reads these host-specific preferences. The trackpad domains
    # managed by nix-darwin alone do not update this copy.
    targets.darwin.currentHostDefaults.NSGlobalDomain = {
      "com.apple.trackpad.threeFingerDragGesture" = false;
      "com.apple.trackpad.threeFingerHorizSwipeGesture" = 0;
      "com.apple.trackpad.threeFingerVertSwipeGesture" = 0;
      "com.apple.trackpad.fourFingerHorizSwipeGesture" = 2;
      "com.apple.trackpad.fourFingerVertSwipeGesture" = 2;
    };
  };

  flake.aspects.paneru-base.darwin =
      { lib, ... }:
      {
        imports = [ inputs.paneru.darwinModules.paneru ];
        system.defaults = {
          # Paneru manages one independent strip per display and requires the
          # corresponding macOS Mission Control setting.
          spaces.spans-displays = false;
          trackpad = {
            # Reserve three-finger gestures for Paneru's direct strip navigation.
            TrackpadThreeFingerDrag = lib.mkForce false;
            # Reserve three-finger swipes for Paneru instead of Mission Control.
            TrackpadThreeFingerHorizSwipeGesture = lib.mkForce 0;
            TrackpadThreeFingerVertSwipeGesture = lib.mkForce 0;
            # Put mission control and space switching on 4 fingers
            TrackpadFourFingerHorizSwipeGesture = lib.mkForce 2;
            TrackpadFourFingerVertSwipeGesture = lib.mkForce 2;
          };
        };

        services.paneru = {
          enable = true;
          settings = {
            options = {
              focus_follows_mouse = true;
              mouse_follows_focus = true;
              preset_column_widths = [
                0.25
                0.33
                0.5
                0.66
                0.75
                1.0
              ];
            };

            swipe = {
              sensitivity = 0.25;
              deceleration = 5.0;
              continuous = true;
              gesture = {
                fingers_count = 3;
                direction = "Natural";
                vertical = true;
              };
              # Paneru defaults this to Alt when omitted and has no explicit
              # switch to disable modifier-scroll. Reserve an impractical
              # chord so ordinary Alt-scroll passes through to applications.
              scroll.modifier = "ctrl + alt + cmd + shift";
            };

            bindings = {
              window_focus_west = "alt - h";
              window_focus_south = "alt - j";
              window_focus_north = "alt - k";
              window_focus_east = "alt - l";

              window_swap_west = "alt + shift - h";
              window_swap_south = "alt + shift - j";
              window_swap_north = "alt + shift - k";
              window_swap_east = "alt + shift - l";

              window_shrink = "alt + shift - minus";
              window_grow = "alt + shift - equal";
              window_fullwidth = "alt - f";
              window_manage = "alt + shift - space";
              window_stack = "alt - slash";
              window_unstack = "alt - comma";
              window_nextdisplay = "alt + shift - tab";
              window_center = "alt - c";
              window_balance = "alt - b";
              window_copyrule = "ctrl + alt - c";

              window_virtualnum_1 = "alt - 1";
              window_virtualnum_2 = "alt - 2";
              window_virtualnum_3 = "alt - 3";
              window_virtualnum_4 = "alt - 4";
              window_virtualnum_5 = "alt - 5";
              window_virtualnum_6 = "alt - 6";
              window_virtualnum_7 = "alt - 7";
              window_virtualnum_8 = "alt - 8";
              window_virtualnum_9 = "alt - 9";
              window_virtualnum_10 = "alt - 0";

              window_virtualmovenum_1 = "alt + shift - 1";
              window_virtualmovenum_2 = "alt + shift - 2";
              window_virtualmovenum_3 = "alt + shift - 3";
              window_virtualmovenum_4 = "alt + shift - 4";
              window_virtualmovenum_5 = "alt + shift - 5";
              window_virtualmovenum_6 = "alt + shift - 6";
              window_virtualmovenum_7 = "alt + shift - 7";
              window_virtualmovenum_8 = "alt + shift - 8";
              window_virtualmovenum_9 = "alt + shift - 9";
              window_virtualmovenum_10 = "alt + shift - 0";

              quit = "ctrl + alt - q";
              restart = "ctrl + alt - r";
            };

            windows.firefox-picture-in-picture = {
              bundle_id = "org.mozilla.firefox";
              title = "Picture-in-Picture";
              floating = true;
            };
          };
        };
      };
}
