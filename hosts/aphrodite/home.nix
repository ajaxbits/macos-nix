{
  pkgs,
  self,
  ...
}:
{
  imports = [
    "${self}/common/fish"
    "${self}/common/zellij"
  ];
  home = {
    stateVersion = "22.05";
    packages = with pkgs; [
      coreutils
      curl
      entr
      gh
      neofetch
      nix-output-monitor
      xh
      zoxide
    ];
  };

  programs = {
    atuin = {
      enable = true;
      enableBashIntegration = true;
      enableFishIntegration = true;
    };
    direnv = {
      enable = true;
      nix-direnv = {
        enable = true;
      };
      enableBashIntegration = true;
    };
    eza.enable = true;
    jq.enable = true;
    lazygit.enable = true;
  };
}
