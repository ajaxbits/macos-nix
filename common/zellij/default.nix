{
  programs.zellij = {
    enable = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
    enableZshIntegration = true;
  };

  xdg.configFile."zellij/config.kdl".text = builtins.readFile ./zellij-config.kdl;
}
