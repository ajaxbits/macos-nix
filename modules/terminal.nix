{ config, ... }:
let
  common = config.flake.modules.homeManager.terminal-common;
in
{
  flake.aspects.terminal = {
    # Terminal owns its workspace and window-management integration.
    darwin =
      { pkgs, ... }:
      {
        fonts.packages = [ pkgs.atkinson-hyperlegible-mono ];

        services.aerospace.settings =
          let
            mod = "alt";
            workspace = {
              name = "[T]erminal";
              binding = "t";
              appId = "com.mitchellh.ghostty";
            };
          in
          {
            mode.main.binding = {
              "${mod}-${workspace.binding}" = "workspace ${workspace.name}";
              "${mod}-shift-${workspace.binding}" = "move-node-to-workspace ${workspace.name}";
            };
            on-window-detected = [
              {
                "if".app-id = workspace.appId;
                run = [
                  "layout floating"
                  "move-node-to-workspace ${workspace.name}"
                ];
              }
            ];
          };
      };

    homeManager =
      { pkgs, ... }:
      {
        imports = [ common ];
        programs.ghostty = {
          package = pkgs.ghostty-bin;
          settings = {
            window-decoration = "none";
            keybind = [
              "cmd+shift+backslash=new_split:right"
              "cmd+shift+minus=new_split:down"

              "cmd+shift+l=goto_split:right"
              "cmd+shift+h=goto_split:left"
              "cmd+shift+k=goto_split:up"
              "cmd+shift+j=goto_split:down"

              "cmd+ctrl+l=resize_split:right,20"
              "cmd+ctrl+h=resize_split:left,20"
              "cmd+ctrl+k=resize_split:up,20"
              "cmd+ctrl+j=resize_split:down,20"

              "global:cmd+shift+backquote=toggle_quick_terminal"
            ];
          };
        };
      };
  };

  flake.aspects.terminal-common.homeManager = {
    programs.ghostty = {
      enable = true;
      enableFishIntegration = true;
      installBatSyntax = true;
      settings = {
        copy-on-select = true;
        desktop-notifications = true;
        font-family = "Atkinson Hyperlegible Mono";
        font-family-bold = "Atkinson Hyperlegible Mono SemiBold";
        font-family-bold-italic = "Atkinson Hyperlegible Mono SemiBold Italic";
        font-size = 13;
        theme = "Gruvbox Dark";
        window-vsync = true;
      };
    };
  };
}
