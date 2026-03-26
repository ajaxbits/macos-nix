{
  flake.modules.homeManager.terminal =
    { pkgs, ... }:
    {
      programs.ghostty = {
        enable = true;
        package = pkgs.ghostty-bin;
        enableFishIntegration = true;
        installBatSyntax = true;
        settings = {
          copy-on-select = true;
          desktop-notifications = true;
          font-family = "Atkinson Hyperlegible Mono Light";
          font-family-bold = "Atkinson Hyperlegible Mono SemiBold";
          font-family-bold-italic = "Atkinson Hyperlegible Mono SemiBold Italic";
          font-size = 14;
          theme = "Gruvbox Dark";

          window-vsync = true;

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

      programs.zellij = {
        enable = true;
      };

      xdg.configFile."zellij/config.kdl".text = builtins.readFile ./terminal/zellij-config.kdl;
    };
}
