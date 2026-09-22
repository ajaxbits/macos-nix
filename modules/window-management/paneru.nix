{ inputs, ... }:
{
  flake.aspects.paneru-base.darwin =
    { pkgs, ... }:
    {
      imports = [ inputs.paneru.darwinModules.paneru ];
      # Paneru manages one independent strip per display and requires the
      # corresponding macOS Mission Control setting.
      system.defaults.spaces.spans-displays = false;

      services.paneru = {
        enable = true;
        # Remove after https://github.com/karinushka/paneru/pull/399 is merged
        # and the flake input includes it. Scroll events can omit side-specific
        # modifier flags, especially when keyboard and pointing devices differ.
        package =
          inputs.paneru.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs
            (oldAttrs: {
              patches = (oldAttrs.patches or [ ]) ++ [ ./paneru-scroll-modifiers.patch ];
            });
        settings = {
          # Paneru's deserialization fallback produces an empty list when the
          # entire options table is absent, making resize a no-op and leaving
          # the status menu empty. Keep its documented defaults explicit.
          options.preset_column_widths = [
            0.25
            0.33333
            0.5
            0.66667
            0.75
            1.0
            1.5
            2.0
          ];

          # Paneru intercepts scrolling only while Option is held and leaves
          # ordinary trackpad gestures untouched.
          swipe.scroll.modifier = "alt";

          bindings = {
            window_focus_west = "alt - h";
            window_focus_south = "alt - j";
            window_focus_north = "alt - k";
            window_focus_east = "alt - l";

            window_swap_west = "alt + shift - h";
            window_swap_south = "alt + shift - j";
            window_swap_north = "alt + shift - k";
            window_swap_east = "alt + shift - l";

            window_resize = "alt - rightbracket";
            window_shrink = "alt - leftbracket";
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
