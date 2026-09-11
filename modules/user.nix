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
            profile = mkOption {
              type = types.enum [
                "personal"
                "work"
              ];
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
            gitName = mkOption { type = types.str; };
            gitEmail = mkOption { type = types.str; };
            ageIdentityPath = mkOption {
              type = types.addCheck types.str (
                path: lib.hasPrefix "/" path && !(lib.hasPrefix "/nix/store/" path)
              );
              description = "Absolute runtime age identity path outside the Nix store";
            };
            flakeDirectory = mkOption { type = types.str; };
            synthetic = mkOption {
              type = types.bool;
              default = false;
            };
          };
        };
      };
    };
in
{
  flake.modules.darwin.host = hostOptions;
  flake.modules.homeManager.host = hostOptions;

  flake.modules.darwin.user =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      host = config.macosNix.host;
    in
    {
      system.primaryUser = host.userName;
      nix.settings.trusted-users = lib.mkIf host.nixTrustedUser [ host.userName ];

      programs.zsh.enable = true;
      programs.fish.enable = true;

      users.knownUsers = lib.mkIf host.manageUser [ host.userName ];
      users.users = lib.mkIf host.manageUser {
        ${host.userName} = {
          description = host.fullName;
          home = host.homeDirectory;
          shell = pkgs.fish;
          uid = host.uid;
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

  flake.modules.homeManager.user =
    { config, ... }:
    let
      host = config.macosNix.host;
    in
    {
      home = {
        username = host.userName;
        homeDirectory = host.homeDirectory;
        stateVersion = host.homeStateVersion;
      };
    };
}
