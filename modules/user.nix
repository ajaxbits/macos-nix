# Host metadata and user identity shared across darwin and home-manager.
let
  hostOptions =
    { lib, ... }:
    let
      inherit (lib) mkOption types;
    in
    {
      options.macosNix.host = mkOption {
        type = types.submodule {
          options = {
            outputName = mkOption { type = types.str; };
            hostName = mkOption { type = types.str; };
            # mkDarwinConfiguration validates this against both profile registries.
            profile = mkOption {
              type = types.str;
            };
            system = mkOption { type = types.str; };
            userName = mkOption { type = types.str; };
            fullName = mkOption { type = types.str; };
            homeDirectory = mkOption { type = types.str; };
            uid = mkOption {
              type = types.nullOr types.ints.unsigned;
              default = null;
            };
            manageUser = mkOption { type = types.bool; };
            nixTrustedUser = mkOption { type = types.bool; };
            darwinStateVersion = mkOption { type = types.int; };
            homeStateVersion = mkOption { type = types.str; };
            homeManagerBackupExtension = mkOption {
              type = types.nullOr types.str;
              default = null;
            };
            gitName = mkOption { type = types.str; };
            gitEmail = mkOption { type = types.str; };
            ageIdentityPath = mkOption {
              type = types.addCheck types.str (
                path: lib.hasPrefix "/" path && !(lib.hasPrefix "/nix/store/" path)
              );
              description = "Absolute runtime age identity path outside the Nix store";
            };
            ageIdentityType = mkOption {
              type = types.enum [
                "legacy-ssh"
                "secure-enclave"
              ];
            };
            flakeDirectory = mkOption { type = types.str; };
            synthetic = mkOption {
              type = types.bool;
              default = false;
            };
            deploymentReady = mkOption {
              type = types.bool;
              default = false;
            };
          };
        };
      };
    };
in
{
  flake.modules = {
    darwin = {
      host = hostOptions;

      user =
        {
          config,
          pkgs,
          lib,
          ...
        }:
        let
          inherit (config.macosNix) host;
        in
        {
          system.primaryUser = host.userName;
          nix.settings.trusted-users = lib.mkIf host.nixTrustedUser [ host.userName ];

          programs.zsh.enable = true;
          programs.fish.enable = true;
          environment.shells = [ pkgs.fish ];

          users.knownUsers = lib.mkIf host.manageUser [ host.userName ];
          users.users = lib.mkIf host.manageUser {
            ${host.userName} = {
              inherit (host) uid;
              description = host.fullName;
              home = host.homeDirectory;
              shell = pkgs.fish;
            };
          };

          environment.variables = {
            EDITOR = "nvim";
          };

          assertions = [
            {
              assertion = !host.manageUser || host.uid != null;
              message = "a managed macosNix host user requires a UID";
            }
          ];
        };
    };

    homeManager = {
      host = hostOptions;

      user =
        { config, lib, ... }:
        let
          inherit (config.macosNix) host;
        in
        {
          home = {
            username = lib.mkForce host.userName;
            homeDirectory = lib.mkForce host.homeDirectory;
            stateVersion = host.homeStateVersion;
          };

          # Suppress macOS login banners such as "Last login".
          home.file.".hushlogin".text = "";
        };
    };
  };
}
