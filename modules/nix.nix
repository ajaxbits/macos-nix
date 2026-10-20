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
          # ponytail: backport of NixOS/nixpkgs#574509; drop once it lands in our nixpkgs.
          (final: prev: {
            atuin = prev.atuin.overrideAttrs (old: {
              nativeCheckInputs = (old.nativeCheckInputs or [ ]) ++ [ final.writableTmpDirAsHomeHook ];
              preCheck = "";
              env = (old.env or { }) // {
                ATUIN_E2E_BASH = final.lib.getExe (
                  final.writeShellScriptBin "bash" ''
                    NOSYSBASHRC=1 exec ${final.lib.getExe final.bashInteractive} "$@"
                  ''
                );
              };
            });
          })
        ];
      };

      nix.package = lixPackageSet.lix;

      nix = {
        settings = {
          trusted-substituters = [ "https://cache.garnix.io" ];
          trusted-public-keys = [
            "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
          ];
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
}
