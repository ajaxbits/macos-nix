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
    self.homeManagerModules.default
    inputs.agenix.homeManagerModules.default
    "${self}/common/terminal/ghostty"
  ];

  components.opencode = {
    enable = true;
    package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.opencode;
    kagiApiKeyFile = config.age.secrets.kagi_api_key.path;
  };

  age = {
    identityPaths = [ "/Users/${user}/.ssh/bitwarden" ];
    secrets = {
      kagi_api_key.file = ../../secrets/kagi_api_key.age;
    };
  };

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
