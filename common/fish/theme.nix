{ pkgs, ... }:
{
  home.packages = with pkgs; [
    fishPlugins.gruvbox
  ];
  programs.fish.shellInit = # fish
    ''
      theme_gruvbox dark
    '';
}
