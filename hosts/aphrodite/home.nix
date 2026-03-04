{
  pkgs,
  self,
  inputs,
  config,
  user,
  ...
}:
{
  imports = [
    "${self}/common/ai/opencode"
    "${self}/common/fish"
    "${self}/common/vcs"
    "${self}/common/zellij"
    inputs.agenix.homeManagerModules.default
  ];

  age = {
    identityPaths = [ "/Users/${user}/.ssh/bitwarden" ];
    secrets = {
      kagi_api_key.file = ../../secrets/kagi_api_key.age;
    };
  };

  programs.fish.interactiveShellInit = ''
    if test -r ${config.age.secrets.kagi_api_key.path}
      set -gx KAGI_API_KEY (string trim (cat ${config.age.secrets.kagi_api_key.path}))
    end
  '';

  home = {
    stateVersion = "22.05";
    packages = with pkgs; [
      bat
      coreutils
      curl
      entr
      fx
      gh
      git
      jujutsu
      neofetch
      nix-output-monitor
      seventeenlands
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
