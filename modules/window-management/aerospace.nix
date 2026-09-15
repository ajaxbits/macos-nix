{
  flake.modules.darwin = {
    aerospace-base =
      {
        config,
        pkgs,
        lib,
        ...
      }:
      let
        inherit (lib)
          concatMapAttrs
          concatMap
          mkOption
          types
          ;

        mod = "alt";

        baseWorkspaces = {
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
        };

        workspaces = builtins.mapAttrs (
          id: workspace:
          workspace
          // {
            apps = workspace.apps or [ ];
            binding = if (workspace.binding or null) == null then id else workspace.binding;
          }
        ) (baseWorkspaces // config.macosNix.aerospace.workspaces);

        switchToWorkspace = ws: "workspace ${ws.name}";
        moveToWorkspace = ws: "move-node-to-workspace ${ws.name}";

        appCondition =
          app:
          if builtins.isString app || app.id != null then
            { app-id = if builtins.isString app then app else app.id; }
          else
            { app-name-regex-substring = "^${lib.escapeRegex app.name}$"; };

        appMatcherType = types.either types.str (
          types.addCheck (types.submodule {
            options = {
              id = mkOption {
                type = types.nullOr types.str;
                default = null;
              };
              name = mkOption {
                type = types.nullOr types.str;
                default = null;
              };
            };
          }) (app: ((app.id or null) == null) != ((app.name or null) == null))
        );

        workspaceBindings = concatMapAttrs (_: ws: {
          "${mod}-${ws.binding}" = switchToWorkspace ws;
          "${mod}-shift-${ws.binding}" = moveToWorkspace ws;
        }) workspaces;

        workspaceRules = concatMap (
          ws:
          map (app: {
            "if" = appCondition app // {
              during-aerospace-startup = true;
            };
            run = [ (moveToWorkspace ws) ];
          }) ws.apps
        ) (builtins.attrValues workspaces);

        runAndReturnToMain = command: [
          command
          "mode main"
        ];

        mainBindings = workspaceBindings // {
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
          esc = runAndReturnToMain "reload-config";
          r = runAndReturnToMain "flatten-workspace-tree";
          f = runAndReturnToMain "layout floating tiling";
          backspace = runAndReturnToMain "close-all-windows-but-current";
          "${mod}-shift-h" = runAndReturnToMain "join-with left";
          "${mod}-shift-j" = runAndReturnToMain "join-with down";
          "${mod}-shift-k" = runAndReturnToMain "join-with up";
          "${mod}-shift-l" = runAndReturnToMain "join-with right";
        };
      in
      {
        options.macosNix.aerospace.workspaces = mkOption {
          type = types.attrsOf (
            types.submodule {
              options = {
                apps = mkOption {
                  type = types.listOf appMatcherType;
                  default = [ ];
                  example = [
                    "org.mozilla.firefox"
                    { name = "Firefox"; }
                    { id = "com.google.Chrome"; }
                  ];
                  description = ''
                    Applications assigned to this workspace. A string is treated as a bundle ID;
                    use an attribute set with either `id` or `name` for an explicit match.
                  '';
                };
                binding = mkOption {
                  type = types.nullOr types.str;
                  default = null;
                };
                name = mkOption { type = types.str; };
              };
            }
          );
          default = { };
        };
        config = {
          system.defaults.dock.expose-group-apps = true;
          services.aerospace = {
            # Keep the complete AeroSpace configuration available for an easy
            # rollback, but do not let two window managers control the same
            # windows.
            enable = false;
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

              on-window-detected = workspaceRules ++ [
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
      };

    aerospace-personal = {
      macosNix.aerospace.workspaces = {
        notes = {
          apps = [ "com.roam-research.desktop-app" ];
          binding = "n";
          name = "[N]otes";
        };
        messages = {
          name = "[M]essages";
          binding = "m";
          apps = [ "com.apple.MobileSMS" ];
        };
      };
    };

    aerospace-work = {
      macosNix.aerospace.workspaces = {
        meet = {
          name = "[M]eet";
          binding = "m";
          apps = [
            "us.zoom.xos"
            { name = "Google Meet"; }
          ];
        };
        notes = {
          apps = [ "com.logseq.logseq" ];
          binding = "n";
          name = "[N]otes";
        };
        slack = {
          apps = [ "com.tinyspeck.slackmacgap" ];
          binding = "s";
          name = "[S]lack";
        };
      };
    };
  };
}
