# Nix/Lix package manager and nixpkgs configuration
{ inputs, ... }:
{
  flake.aspects.nix.darwin =
    { config, pkgs, ... }:
    let
      lixPackageSet = pkgs.lixPackageSets.latest;
    in
    {
      nixpkgs = {
        config = {
          allowBroken = true;
          allowUnfree = true;
        };
        hostPlatform = config.macosNix.host.system;
        overlays = [
          inputs.nur.overlays.default
          (_: _: {
            inherit (lixPackageSet)
              colmena
              nil
              nix-eval-jobs
              nix-fast-build
              nixpkgs-review
              nixpkgs-reviewFull
              nurl
              ;
          })
        ];
      };

      nix.package = lixPackageSet.lix;

      nix = {
        # Flakes only; drops the nonexistent root channels entry from NIX_PATH.
        channel.enable = false;
        settings = {
          substituters = [ "https://cache.nix.ajax.casa/patroclus?priority=10" ];
          trusted-public-keys = [ "patroclus:Qy1DbSYS2lL+DDxXY+e0C4ryF7COHyf6LN4g4OtcbW4=" ];
          # The cache is private; the daemon reads the agenix-managed netrc below.
          netrc-file = "${config.macosNix.host.homeDirectory}/.config/nix/netrc";
        };
        gc = {
          automatic = true;
          interval = {
            Day = 7;
          };
          options = "--delete-older-than 30d";
        };
        optimise.automatic = true;
        extraOptions = ''
          experimental-features = nix-command flakes
          extra-platforms = x86_64-darwin aarch64-darwin
        '';
      };
    };

  # Push every new store path to patroclus; attic skips paths already
  # signed by cache.nixos.org.
  flake.aspects.nix.homeManager =
    { config, pkgs, ... }:
    {
      age.secrets = {
        nix_netrc = {
          file = ../secrets/nix_netrc.age;
          path = "${config.xdg.configHome}/nix/netrc";
        };
        attic_token = {
          file = ../secrets/attic_token.age;
          path = "${config.xdg.configHome}/attic/token";
        };
      };

      home.packages = [ pkgs.attic-client ];

      xdg.configFile."attic/config.toml" = {
        # Replaces the hand-placed config that inlined the token.
        force = true;
        text = ''
          default-server = "patroclus"

          [servers.patroclus]
          endpoint = "https://cache.nix.ajax.casa"
          token-file = "${config.age.secrets.attic_token.path}"
        '';
      };

      launchd.agents.attic-watch-store = {
        enable = true;
        config = {
          ProgramArguments = [
            "${pkgs.attic-client}/bin/attic"
            "watch-store"
            "patroclus"
          ];
          RunAtLoad = true;
          KeepAlive = true;
          # Back off while offline or before agenix has decrypted the token.
          ThrottleInterval = 30;
          StandardOutPath = "${config.home.homeDirectory}/Library/Logs/attic-watch-store.log";
          StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/attic-watch-store.log";
        };
      };
    };
}
