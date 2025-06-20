{
  inputs,
  pkgs,
  user,
  ...
}:
{
  imports = [
    ./brew.nix
    ../../common/aerospace
  ];
  nix = {
    settings = {
      trusted-users = [
        "@admin"
        user
      ];
      trusted-substituters = [ "https://cache.garnix.io" ];
      extra-substituters = [ "https://cache.lix.systems" ];
      trusted-public-keys = [
        "cache.lix.systems:aBnZUw8zA7H35Cz2RyKFVs3H4PlGTLawyY5KRbvJR8o="
        "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      ];
    };
    gc = {
      automatic = true;
      interval = {
        Day = 7;
      };
      options = ''
        --delete-older-than 30d
      '';
    };
    optimise.automatic = true;
    extraOptions = ''
      experimental-features = nix-command flakes
      extra-platforms = x86_64-darwin aarch64-darwin
    '';
  };

  programs.zsh.enable = true;
  programs.fish.enable = true;
  system.primaryUser = user;
  users.knownUsers = [ user ];
  users.users.${user} = {
    description = "Alex Jackson";
    home = "/Users/${user}";
    shell = pkgs.fish;
    uid = 501;
  };

  virtualisation.podman = {
    enable = true;
    compose.enable = true;
    dockerCompat = true;
  };

  system = {
    stateVersion = 5;
    defaults = {
      finder = {
        AppleShowAllExtensions = true;
        QuitMenuItem = true;
        FXEnableExtensionChangeWarning = false;
      };
      dock = {
        autohide = true;
        orientation = "left";
      };
      screencapture.location = "/tmp";
      trackpad = {
        ActuationStrength = 0;
        Clicking = true; # tap to click
        FirstClickThreshold = 0; # "light" haptic feedback
        TrackpadThreeFingerDrag = true;
      };
      NSGlobalDomain = {
        "com.apple.sound.beep.feedback" = 0;
        AppleInterfaceStyle = "Dark";
      };
    };
    keyboard.enableKeyMapping = true;
    keyboard.remapCapsLockToEscape = true;
  };

  environment = {
    systemPackages = with pkgs; [
      du-dust
      eza
      fd
      gron
      hck
      ripgrep
      sd
      uv
      viddy
      winetricks

      inputs.nvim.packages.aarch64-darwin.default
    ];

    variables = {
      EDITOR = "nvim";
      SSH_AUTH_SOCK = "/Users/${user}/.bitwarden-ssh-agent.sock";
    };
  };

  security.pam.services.sudo_local.touchIdAuth = true;
}
