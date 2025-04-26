{ lib, ... }:
let
  # All possible modifiers: cmd, alt, ctrl, shift
  mod = "alt";

  workspaces = import ./workspaces.nix { inherit lib mod; };
  mainBindings = workspaces.bindings // (import ./bindings/main.nix { inherit mod; });
in
{
  services.aerospace.settings = {
    after-login-command = [ ];
    after-startup-command = [ ];

    # Normalizations. See: https://nikitabobko.github.io/AeroSpace/guide#normalization
    enable-normalization-flatten-containers = true;
    enable-normalization-opposite-orientation-for-nested-containers = true;

    # See: https://nikitabobko.github.io/AeroSpace/guide#layouts
    # The "accordion-padding" specifies the size of accordion padding
    # You can set 0 to disable the padding feature
    accordion-padding = 30;

    # Possible values: tiles|accordion
    default-root-container-layout = "tiles";

    # Possible values: horizontal|vertical|auto
    # "auto" means: wide monitor (anything wider than high) gets horizontal orientation,
    #               tall monitor (anything higher than wide) gets vertical orientation
    default-root-container-orientation = "auto";

    # Possible values: (qwerty|dvorak)
    # See https://nikitabobko.github.io/AeroSpace/guide#key-mapping
    key-mapping.preset = "qwerty";

    # Mouse follows focus when focused monitor changes
    # Drop it from your config, if you don"t like this behavior
    # See https://nikitabobko.github.io/AeroSpace/guide#on-focus-changed-callbacks
    # See https://nikitabobko.github.io/AeroSpace/commands#move-mouse
    on-focused-monitor-changed = [ "move-mouse monitor-lazy-center" ];

    gaps = import ./gaps.nix;
    mode = {
      # "main" binding mode declaration
      # See: https://nikitabobko.github.io/AeroSpace/guide#binding-modes
      main.binding = mainBindings;
      # "service" binding mode declaration.
      # See: https://nikitabobko.github.io/AeroSpace/guide#binding-modes
      service.binding = import ./bindings/service.nix;
    };

    on-window-detected = workspaces.onWindowDetected ++ (import ./onWindowDetected.nix);
  };
}
