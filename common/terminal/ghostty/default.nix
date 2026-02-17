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
      font-family = "Atkinson Hyperlegible Mono Light"; # TODO: factor out one day
      font-family-bold = "Atkinson Hyperlegible Mono SemiBold"; # TODO: factor out one day
      font-family-bold-italic = "Atkinson Hyperlegible Mono SemiBold Italic"; # TODO: factor out one day
      font-size = 14;
      theme = "GruvboxDark";
      window-decoration = false;
      window-vsync = false;

      keybind = [
        "cmd+h=previous_tab"
        "cmd+l=next_tab"
        "cmd+shift+l=goto_split:right"
        "cmd+shift+h=goto_split:left"
        "cmd+shift+k=goto_split:up"
        "cmd+shift+j=goto_split:down"
        "cmd+ctrl+l=resize_split:right,20"
        "cmd+ctrl+h=resize_split:left,20"
        "cmd+ctrl+k=resize_split:up,20"
        "cmd+ctrl+j=resize_split:down,20"
      ];
    };
  };
}
