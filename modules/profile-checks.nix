# Evaluation-only checks for profile selection and host-derived settings.
{
  config,
  lib,
  ...
}:
{
  flake.aspects.profile-check-unselected-marker.darwin = {
    environment.variables.PROFILE_CHECK_UNSELECTED = "incorrectly-selected";
  };

  flake.aspects.profile-check-unselected-marker.homeManager = {
    home.sessionVariables.PROFILE_CHECK_UNSELECTED = "incorrectly-selected";
  };

  perSystem =
    { pkgs, ... }:
    let
      mkHost = config.macosNix.mkDarwinConfiguration;
      mkFixture =
        {
          outputName,
          profile,
          userName,
          uid,
        }:
        {
          inherit
            outputName
            profile
            userName
            uid
            ;
          hostName = outputName;
          system = "aarch64-darwin";
          fullName = "Synthetic ${profile}";
          homeDirectory = "/Users/${userName}";
          manageUser = true;
          nixTrustedUser = true;
          darwinStateVersion = 5;
          homeStateVersion = "22.05";
          homeManagerBackupExtension = if profile == "personal" then "bak" else null;
          gitName = "Synthetic ${profile}";
          gitEmail = "${userName}@example.invalid";
          ageIdentityPath = "/Users/${userName}/Library/Application Support/agenix/identity.txt";
          ageIdentityType = "secure-enclave";
          flakeDirectory = "/fixture/${profile} checkout with spaces";
          synthetic = true;
          deploymentReady = true;
        };

      personalHost = mkFixture {
        outputName = "profile-check-personal";
        profile = "personal";
        userName = "personal-fixture";
        uid = 601;
      };
      workHost = mkFixture {
        outputName = "profile-check-work";
        profile = "work";
        userName = "work-fixture";
        uid = 602;
      };

      personal = (mkHost personalHost).config;
      work = (mkHost workHost).config;
      personalHome = personal.home-manager.users.${personalHost.userName};
      workHome = work.home-manager.users.${workHost.userName};
      realPersonal = config.flake.darwinConfigurations."Alexs-MacBook-Air".config;
      realPersonalHome = realPersonal.home-manager.users.ajax;
      realWork = config.flake.darwinConfigurations.K1H96QD74C.config;
      firefoxProfile = personalHome.programs.firefox.profiles."default-release-2";
      firefoxPolicies = personalHome.targets.darwin.defaults."org.mozilla.firefox";
      workFirefoxProfile = workHome.programs.firefox.profiles."default-release-2";
      workFirefoxPolicies = workHome.targets.darwin.defaults."org.mozilla.firefox";

      packageNames = packages: map lib.getName packages;
      normalizePackageName =
        name:
        if lib.hasPrefix "podman-compose-docker-compat-" name then
          "podman-compose-docker-compat"
        else if lib.hasPrefix "podman-docker-compat-" name then
          "podman-docker-compat"
        else
          name;
      normalizedPackageNames =
        packages:
        builtins.sort builtins.lessThan (
          map (package: normalizePackageName (lib.getName package)) packages
        );
      personalSystemPackages = packageNames personal.environment.systemPackages;
      workSystemPackages = packageNames work.environment.systemPackages;
      personalHomePackages = packageNames personalHome.home.packages;
      workHomePackages = packageNames workHome.home.packages;
      personalFishFunctions = builtins.attrNames personalHome.programs.fish.functions;
      workFishFunctions = builtins.attrNames workHome.programs.fish.functions;
      caskNames = casks: map (cask: if builtins.isString cask then cask else cask.name) casks;
      personalCasks = caskNames personal.homebrew.casks;
      workCasks = caskNames work.homebrew.casks;
      forbiddenCasks = [
        "docker"
        "docker-desktop"
        "homerow"
        "slack"
        "talon"
        "tor-browser"
        "visual-studio-code"
      ];
      forbiddenBrews = [
        "cocoapods"
        "container"
        "jfrog-cli"
        "maven"
        "mpv"
      ];
      personalHasKagi = personalHome.age.secrets ? kagi_api_key;
      workHasKagi = workHome.age.secrets ? kagi_api_key;
      hasManagedOpenCodeConfig =
        home:
        home.programs.opencode.enable
        || home.programs.mcp.enable
        || home.home.sessionVariables ? OPENCODE_EXPERIMENTAL
        || lib.any (
          path:
          let
            lowerPath = lib.toLower path;
          in
          lib.hasInfix "opencode" lowerPath || lib.hasInfix "/mcp/" lowerPath
        ) (builtins.attrNames home.home.file);
      workHasDockerCompat = lib.any (name: lib.hasInfix "docker-compat" name) workSystemPackages;
      hasFoundationWallpaper =
        configuration:
        let
          # Only the script nix-darwin assembles is ever executed, so assert
          # against that rather than a free-standing activation attribute.
          activation = configuration.system.activationScripts.script.text;
        in
        lib.hasInfix "lava-dark.jpg" activation
        # Activation runs as root, so the picture must be set in the user session.
        && lib.hasInfix "asuser" activation
        # The image must be its own store path. A reference into the flake source
        # is not a dependency of the system and can be garbage collected.
        && !lib.hasInfix "-source/assets/lava-dark.jpg" activation;

      invalidWork = builtins.tryEval (
        let
          invalid = mkHost (workHost // { synthetic = false; });
        in
        builtins.deepSeq invalid.config.networking.hostName true
      );

      invalidProfile = builtins.tryEval (
        let
          invalid = mkHost (workHost // { profile = "unknown"; });
        in
        builtins.deepSeq invalid.config.networking.hostName true
      );
      workspaceAppIds =
        system: map (callback: callback."if".app-id) system.services.aerospace.settings.on-window-detected;
      personalWorkspaceAppIds = workspaceAppIds personal;
      workWorkspaceAppIds = workspaceAppIds work;
      realPersonalWorkspaceAppIds = workspaceAppIds realPersonal;
      realWorkWorkspaceAppIds = workspaceAppIds realWork;

      expectedPersonalSystemPackages = builtins.sort builtins.lessThan [
        "bash-interactive"
        "curl"
        "darwin-help"
        "darwin-manpages"
        "darwin-manual-html"
        "darwin-option"
        "darwin-rebuild"
        "darwin-uninstaller"
        "darwin-version"
        "du-dust"
        "fd"
        "fish"
        "fish"
        "git"
        "hck"
        "lix"
        "nix-info"
        "nix-zsh-completions"
        "nixvim"
        "podman"
        "podman-compose"
        "podman-compose-docker-compat"
        "podman-docker-compat"
        "paneru-with-lua-wrapped"
        "ripgrep"
        "sd"
        "secretive"
        "texinfo-interactive"
        "uv"
        "vfkit"
        "viddy"
        "zsh"
      ];
      expectedPersonalHomePackages = builtins.sort builtins.lessThan [
        "age"
        "age-plugin-se"
        "agenix"
        "atuin"
        "bat"
        "delta"
        "direnv"
        "entr"
        "eza"
        "firefox-bin"
        "fish"
        "fx"
        "fzf"
        "gh"
        "ghostty-bin"
        "git"
        "git-lfs"
        "gruvbox"
        "hm-session-vars.fish"
        "hm-session-vars.sh"
        "home-configuration-reference-manpage"
        "jq"
        "jujutsu"
        "jujutsu"
        "man-db"
        "nix-output-monitor"
        "opencode2"
        "seventeenlands"
        "starship"
        "xh"
        "yazi"
        "zoxide"
        "zoxide"
      ];
      expectedPersonalCasks = builtins.sort builtins.lessThan [
        "ankerwork"
        "balenaetcher"
        "betterdisplay"
        "bitwarden"
        "calibre"
        "discord"
        "fantastical"
        "helium-browser"
        "hiddenbar"
        "jordanbaird-ice"
        "keepingyouawake"
        "maccy"
        "notesnook"
        "passepartout"
        "podman-desktop"
        "prismlauncher"
        "raspberry-pi-imager"
        "roam-research"
        "rocket"
        "shottr"
        "steam"
        "tailscale-app"
        "vlc"
      ];

      productionRebuildBody = personalHome.programs.fish.functions.nixre;
      assertions = [
        {
          assertion =
            !(personal.environment.variables ? PROFILE_CHECK_UNSELECTED)
            && !(work.environment.variables ? PROFILE_CHECK_UNSELECTED)
            && !(personalHome.home.sessionVariables ? PROFILE_CHECK_UNSELECTED)
            && !(workHome.home.sessionVariables ? PROFILE_CHECK_UNSELECTED);
          message = "an unselected registry aspect entered a profile";
        }
        {
          assertion =
            normalizedPackageNames realPersonal.environment.systemPackages == expectedPersonalSystemPackages
            && normalizedPackageNames realPersonalHome.home.packages == expectedPersonalHomePackages
            && builtins.sort builtins.lessThan (caskNames realPersonal.homebrew.casks) == expectedPersonalCasks
            &&
              builtins.sort builtins.lessThan (builtins.attrNames realPersonal.launchd.user.agents)
              == [ "paneru" ]
            &&
              builtins.sort builtins.lessThan (builtins.attrNames realPersonal.launchd.daemons) == [
                "activate-system"
                "nix-daemon"
                "nix-gc"
                "nix-optimise"
              ]
            &&
              builtins.sort builtins.lessThan (builtins.attrNames realPersonalHome.programs.fish.functions) == [
                "__fish_command_not_found_handler"
                "js"
                "nixre"
                "t"
                "take"
                "y"
              ]
            &&
              builtins.sort builtins.lessThan (builtins.attrNames realPersonalHome.programs.fish.shellAliases)
              == [
                "cat"
                "l"
                "la"
                "ll"
                "lla"
                "ls"
                "lt"
                "v"
              ]
            && !realPersonal.services.aerospace.enable
            && !realWork.services.aerospace.enable
            && realPersonal.services.paneru.enable
            && realWork.services.paneru.enable
            &&
              builtins.hashString "sha256" (builtins.toJSON realPersonal.services.aerospace.settings)
              == "a79f94161367babaaa3ad5f0ffea560ce848b2d4abeffed9ce29a5ba6cfaa4b6"
            &&
              builtins.hashString "sha256" (builtins.toJSON realPersonalHome.programs.ghostty.settings)
              == "841c849aa4b6c5eeb160246ab996e6bd102f8f5eab57f38a1160cef4bd11411b";
          message = "the real personal package, service, shell, window manager, or Ghostty baseline changed";
        }
        {
          assertion =
            personalHome.programs.fish.enable
            && workHome.programs.fish.enable
            && personalHome.programs.git.enable
            && workHome.programs.git.enable
            && personal.security.pam.services.sudo_local.touchIdAuth
            && work.security.pam.services.sudo_local.touchIdAuth;
          message = "foundation modules are missing from a profile";
        }
        {
          assertion = hasFoundationWallpaper personal && hasFoundationWallpaper work;
          message = "foundation wallpaper activation is missing from a profile";
        }
        {
          assertion =
            personalHome.home.file ? ".hushlogin"
            && personalHome.home.file.".hushlogin".text == ""
            && workHome.home.file ? ".hushlogin"
            && workHome.home.file.".hushlogin".text == "";
          message = "Home Manager must suppress macOS login banners for every profile";
        }
        {
          assertion =
            personal.system.defaults.dock.expose-group-apps && work.system.defaults.dock.expose-group-apps;
          message = "Expose application grouping is missing from a profile";
        }
        {
          assertion =
            lib.elem "seventeenlands" personalHomePackages
            && !(lib.elem "seventeenlands" workHomePackages)
            && lib.elem "calibre" personalCasks
            && !(lib.elem "calibre" workCasks)
            && lib.elem "bitwarden" personalCasks
            && !(lib.elem "bitwarden" workCasks);
          message = "personal package or cask boundaries are incorrect";
        }
        {
          assertion =
            lib.any (name: lib.hasPrefix "podman" name) personalSystemPackages
            && !(lib.any (name: lib.hasPrefix "podman" name) workSystemPackages)
            && !(lib.elem "vfkit" workSystemPackages)
            && !workHasDockerCompat;
          message = "the work profile contains personal container tooling";
        }
        {
          assertion =
            lib.elem "awscli2" workHomePackages
            && !(lib.elem "awscli2" personalHomePackages)
            && lib.elem "aws-profile" workFishFunctions
            && !(lib.elem "aws-profile" personalFishFunctions);
          message = "AWS tooling is not isolated to the work profile";
        }
        {
          assertion =
            !(lib.any (name: lib.elem name forbiddenCasks) personalCasks)
            && !(lib.any (name: lib.elem name forbiddenCasks) workCasks)
            && !(lib.any (name: lib.elem name forbiddenBrews) personal.homebrew.brews)
            && !(lib.any (name: lib.elem name forbiddenBrews) work.homebrew.brews);
          message = "a retired or MDM-owned application is declared";
        }
        {
          assertion =
            workHome.home.homeDirectory == workHost.homeDirectory
            && work.homebrew.caskArgs.appdir == "${workHost.homeDirectory}/Applications"
            && lib.hasInfix workHost.homeDirectory work.environment.variables.SSH_AUTH_SOCK
            && !(lib.hasInfix "/Users/ajax" work.environment.variables.SSH_AUTH_SOCK)
            && !(lib.hasInfix "/Users/ajax" work.programs.ssh.extraConfig);
          message = "work user paths are not derived from host facts";
        }
        {
          assertion =
            personalHasKagi
            && workHasKagi
            && !(lib.elem "claude-code" personalHomePackages)
            && lib.elem "claude-code" workHomePackages
            && lib.elem "opencode2" personalHomePackages
            && lib.elem "opencode2" workHomePackages
            && !(lib.elem "opencode" personalHomePackages)
            && !(lib.elem "opencode" workHomePackages)
            && !(lib.elem "claude" personalCasks)
            && lib.elem "claude" workCasks
            && !(lib.elem "claude-update-upside-plugins" personalHomePackages)
            && !(lib.elem "opencode-refresh-upside-skills" personalHomePackages)
            && !(lib.elem "opencode-sync-upside-skills" personalHomePackages)
            && lib.elem "claude-update-upside-plugins" workHomePackages
            && lib.elem "opencode-refresh-upside-skills" workHomePackages
            && lib.elem "opencode-sync-upside-skills" workHomePackages
            && !(hasManagedOpenCodeConfig personalHome)
            && !(hasManagedOpenCodeConfig workHome)
            && workHome.age.identityPaths == [ workHost.ageIdentityPath ]
            && lib.elem "age-plugin-se" personalHomePackages
            && lib.elem "age-plugin-se" workHomePackages
            && lib.elem "agenix" personalHomePackages
            && lib.elem "agenix" workHomePackages
            && !(lib.elem "/Users/ajax/.ssh/bitwarden" workHome.age.identityPaths);
          message = "shared Kagi, AI tooling, desktop app, or identity boundaries are incorrect";
        }
        {
          assertion =
            builtins.attrNames personalHome.launchd.agents == [ "activate-agenix" ]
            && builtins.attrNames workHome.launchd.agents == [
              "activate-agenix"
              "opencode-upside-sync"
            ];
          message = "the profile launch agents differ from the approved exact sets";
        }
        {
          assertion =
            personalHome.programs.git.settings.user.name == personalHost.gitName
            && personalHome.programs.git.settings.user.email == personalHost.gitEmail
            && personalHome.programs.jujutsu.settings.user.name == personalHost.gitName
            && personalHome.programs.jujutsu.settings.user.email == personalHost.gitEmail
            && workHome.programs.git.settings.user.name == workHost.gitName
            && workHome.programs.git.settings.user.email == workHost.gitEmail
            && workHome.programs.jujutsu.settings.user.name == workHost.gitName
            && workHome.programs.jujutsu.settings.user.email == workHost.gitEmail;
          message = "Git and jj identities do not share host metadata";
        }
        {
          assertion = !invalidWork.success;
          message = "a real work host accepted a placeholder Git identity";
        }
        {
          assertion = !invalidProfile.success;
          message = "a host accepted an unregistered profile";
        }
        {
          assertion =
            lib.hasInfix personalHost.flakeDirectory productionRebuildBody
            && lib.hasInfix personalHost.outputName productionRebuildBody
            && !(lib.hasInfix "nix-darwin/master" productionRebuildBody);
          message = "the generated rebuild helper does not use host facts and pinned tooling";
        }
        {
          assertion =
            personal.homebrew.onActivation.cleanup == "zap"
            && personal.homebrew.onActivation.upgrade
            && work.homebrew.onActivation.cleanup == "none"
            && work.homebrew.onActivation.upgrade;
          message = "Homebrew activation policy is incorrect";
        }
        {
          assertion =
            lib.elem "com.roam-research.desktop-app" personalWorkspaceAppIds
            && !(lib.elem "com.tinyspeck.slackmacgap" personalWorkspaceAppIds)
            && lib.elem "com.tinyspeck.slackmacgap" workWorkspaceAppIds
            && !(lib.elem "com.roam-research.desktop-app" workWorkspaceAppIds)
            && lib.elem "com.roam-research.desktop-app" realPersonalWorkspaceAppIds
            && !(lib.elem "com.tinyspeck.slackmacgap" realPersonalWorkspaceAppIds)
            && lib.elem "com.tinyspeck.slackmacgap" realWorkWorkspaceAppIds
            && !(lib.elem "com.roam-research.desktop-app" realWorkWorkspaceAppIds);
          message = "the disabled AeroSpace rollback configuration lost its profile-specific routes";
        }
        {
          assertion =
            personalHome.programs.firefox.enable
            && personalHome.programs.firefox.package != null
            && workHome.programs.firefox.package != null
            && firefoxProfile.path == "ffeb7rvx.default-release-2"
            && firefoxProfile.storeId == "cb8ad46c"
            && firefoxProfile.settings."dom.security.https_only_mode"
            && firefoxProfile.settings."network.trr.custom_uri" == "https://dns.nextdns.io/b698e3"
            && firefoxPolicies.EnterprisePoliciesEnabled
            &&
              firefoxPolicies.ExtensionSettings."uBlock0@raymondhill.net".installation_mode == "normal_installed"
            && firefoxPolicies.ExtensionSettings."uBlock0@raymondhill.net".updates_disabled == false
            &&
              firefoxPolicies.ExtensionSettings."{315f61e5-f0ce-4d6e-a521-70e8da512405}".installation_mode
              == "blocked"
            && firefoxPolicies.ExtensionSettings."plugin@okta.com".installation_mode == "blocked"
            && builtins.length (builtins.attrNames firefoxPolicies.ExtensionSettings) == 19
            && workFirefoxPolicies.EnterprisePoliciesEnabled
            &&
              workFirefoxPolicies.ExtensionSettings."{315f61e5-f0ce-4d6e-a521-70e8da512405}".installation_mode
              == "normal_installed"
            && workFirefoxPolicies.ExtensionSettings."plugin@okta.com".installation_mode == "normal_installed"
            && workFirefoxProfile.settings."dom.security.https_only_mode"
            && workFirefoxProfile.settings."network.trr.custom_uri" == "https://dns.nextdns.io/b698e3"
            && workFirefoxProfile.userChrome != ""
            && workFirefoxProfile.storeId == "7951011d"
            && builtins.length (builtins.attrNames workFirefoxPolicies.ExtensionSettings) == 19;
          message = "the personal or work Firefox extension policy is incorrect";
        }
      ];
      failures = builtins.filter (item: !item.assertion) assertions;
      failureText = lib.concatMapStringsSep "\n" (item: "- ${item.message}") failures;

      helperBody = config.macosNix.mkRebuildFunction {
        checkout = "/fixture/checkout with spaces";
        outputName = "profile-check-personal";
        buildExe = "./stubs/nom";
        sudoExe = "./stubs/sudo";
        rebuildExe = "./stubs/darwin-rebuild";
      };
    in
    {
      checks.profile-composition =
        assert lib.assertMsg (failures == [ ]) "profile composition failures:\n${failureText}";
        pkgs.runCommand "profile-composition-evaluation" { } ''
          touch "$out"
        '';

      checks.rebuild-helper =
        pkgs.runCommand "rebuild-helper-test"
          {
            nativeBuildInputs = [
              pkgs.fish
              pkgs.gnugrep
            ];
            inherit helperBody;
          }
          ''
            mkdir -p stubs
            export HOME="$PWD/home"
            mkdir -p "$HOME"
            cat > stubs/nom <<'EOF'
            #!${pkgs.runtimeShell}
            printf '<%s>\n' "$@" > "$TEST_ROOT/build.args"
            exit "''${BUILD_STATUS:-0}"
            EOF
            cat > stubs/sudo <<'EOF'
            #!${pkgs.runtimeShell}
            printf '<%s>\n' "$@" > "$TEST_ROOT/switch.args"
            exit "''${SWITCH_STATUS:-0}"
            EOF
            cat > stubs/darwin-rebuild <<'EOF'
            #!${pkgs.runtimeShell}
            exit 99
            EOF
            chmod +x stubs/*

            {
              echo 'function nixre'
              printf '%s\n' "$helperBody"
              echo 'end'
            } > helper.fish
            export TEST_ROOT="$PWD"

            fish -c 'source helper.fish; nixre'
            grep -Fx '<--accept-flake-config>' build.args
            grep -Fx '<--no-write-lock-file>' build.args
            grep -Fx '</fixture/checkout with spaces#darwinConfigurations.profile-check-personal.system>' build.args
            grep -Fx '<./stubs/darwin-rebuild>' switch.args
            grep -Fx '<switch>' switch.args
            grep -Fx '<--no-write-lock-file>' switch.args
            grep -Fx '<--flake>' switch.args
            grep -Fx '</fixture/checkout with spaces#profile-check-personal>' switch.args

            rm -f switch.args
            if BUILD_STATUS=17 fish -c 'source helper.fish; nixre'; then
              echo 'failed build unexpectedly succeeded' >&2
              exit 1
            fi
            test ! -e switch.args

            set +e
            SWITCH_STATUS=23 fish -c 'source helper.fish; nixre'
            switch_status=$?
            set -e
            test "$switch_status" = 23

            rm -f switch.args
            if fish -c 'source helper.fish; nixre unexpected'; then
              echo 'unexpected argument was accepted' >&2
              exit 1
            fi
            test ! -e switch.args
            touch "$out"
          '';
    };
}
