{
  flake.modules.darwin.aerospace =
    { pkgs, lib, ... }:
    let
      mod = "alt";

      workspaces = {
        "0".name = "10";
        "1".name = "1";
        "2".name = "2";
        "3".name = "3";
        "4".name = "4";
        "5".name = "5";
        "6".name = "6";
        "7".name = "7";
        "8".name = "8";
        "9".name = "9";
        browser = {
          apps = [ "org.mozilla.firefox" ];
          binding = "b";
          name = "[B]rowser";
        };
        calendar = {
          name = "[C]alendar";
          binding = "c";
          apps = [ "com.flexibits.fantastical2.mac" ];
        };
        drafts = {
          name = "[D]rafts";
          binding = "d";
          apps = [ "com.agiletortoise.Drafts-OSX" ];
        };
        messages = {
          name = "[M]essages";
          binding = "m";
          apps = [ "com.apple.MobileSMS" ];
        };
        notes = {
          apps = [ "com.roam-research.desktop-app" ];
          binding = "n";
          name = "[N]otes";
        };
        slack = {
          name = "[S]lack";
          binding = "s";
          apps = [ "com.tinyspeck.slackmacgap" ];
        };
        terminal = {
          name = "[T]erminal";
          binding = "t";
          apps = [ "com.mitchellh.ghostty" ];
        };
      };

      workspacesWithDefaultValues = builtins.mapAttrs (
        name: value: value // { binding = value.binding or name; }
      ) workspaces;

      assignWorkspace = ws: "workspace ${ws.name}";
      moveToWorkspace = ws: "move-node-to-workspace ${ws.name}";

      wsAssignments = builtins.listToAttrs (
        map (ws: {
          name = "${mod}-${ws.binding}";
          value = assignWorkspace ws;
        }) (builtins.attrValues workspacesWithDefaultValues)
      );

      wsMoves = builtins.listToAttrs (
        map (ws: {
          name = "${mod}-shift-${ws.binding}";
          value = moveToWorkspace ws;
        }) (builtins.attrValues workspacesWithDefaultValues)
      );

      _workspacesWithApps = builtins.filter (
        name: builtins.hasAttr "apps" workspacesWithDefaultValues.${name}
      ) (builtins.attrNames workspacesWithDefaultValues);

      workspaceWindowDetectedCallbacks =
        ws:
        map (app: {
          "if".app-id = app;
          run = [ (moveToWorkspace ws) ];
        }) ws.apps;

      mainBindings =
        wsAssignments
        // wsMoves
        // {
          "${mod}-slash" = "layout tiles horizontal vertical";
          "${mod}-comma" = "layout accordion horizontal vertical";

          cmd-h = [ ];
          cmd-alt-h = [ ];

          "${mod}-h" = "focus left";
          "${mod}-j" = "focus down";
          "${mod}-k" = "focus up";
          "${mod}-l" = "focus right";

          "${mod}-f" = "fullscreen";

          "${mod}-shift-h" = "move left";
          "${mod}-shift-j" = "move down";
          "${mod}-shift-k" = "move up";
          "${mod}-shift-l" = "move right";

          "${mod}-shift-minus" = "resize smart -50";
          "${mod}-shift-equal" = "resize smart +50";

          "${mod}-tab" = "workspace-back-and-forth";
          "${mod}-shift-tab" = "move-workspace-to-monitor --wrap-around next";

          "${mod}-shift-semicolon" = "mode service";
        };

      serviceBindings = {
        esc = [
          "reload-config"
          "mode main"
        ];
        r = [
          "flatten-workspace-tree"
          "mode main"
        ];
        f = [
          "layout floating tiling"
          "mode main"
        ];
        backspace = [
          "close-all-windows-but-current"
          "mode main"
        ];
        alt-shift-h = [
          "join-with left"
          "mode main"
        ];
        alt-shift-j = [
          "join-with down"
          "mode main"
        ];
        alt-shift-k = [
          "join-with up"
          "mode main"
        ];
        alt-shift-l = [
          "join-with right"
          "mode main"
        ];
      };
    in
    {
      services.aerospace = {
        enable = true;
        package = pkgs.aerospace;
        settings = {
          after-login-command = [ ];
          after-startup-command = [ ];

          enable-normalization-flatten-containers = true;
          enable-normalization-opposite-orientation-for-nested-containers = true;

          accordion-padding = 30;
          default-root-container-layout = "tiles";
          default-root-container-orientation = "auto";
          key-mapping.preset = "qwerty";

          on-focused-monitor-changed = [ "move-mouse monitor-lazy-center" ];

          gaps = {
            inner = {
              horizontal = 0;
              vertical = 0;
            };
            outer = {
              left = 0;
              bottom = 0;
              top = 0;
              right = 0;
            };
          };

          mode = {
            main.binding = mainBindings;
            service.binding = serviceBindings;
          };

          on-window-detected =
            lib.flatten (
              map (
                attrName: workspaceWindowDetectedCallbacks workspacesWithDefaultValues.${attrName}
              ) _workspacesWithApps
            )
            ++ [
              {
                "if" = {
                  app-id = "org.mozilla.firefox";
                  window-title-regex-substring = "Picture-in-Picture";
                };
                run = [ "layout floating" ];
              }
            ];
        };
      };
    };
}
