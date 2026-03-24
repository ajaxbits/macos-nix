# Nix/Lix package manager and nixpkgs configuration
{ inputs, ... }:
{
  flake.modules.darwin.nix = { pkgs, ... }:
  let
    lixPackageSet = pkgs.lixPackageSets.latest;
  in
  {
    nixpkgs = {
      config = {
        allowBroken = true;
        allowUnfree = true;
      };
      hostPlatform = "aarch64-darwin";
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
      settings = {
        trusted-users = [ "@admin" ];
        trusted-substituters = [ "https://cache.garnix.io" ];
        trusted-public-keys = [
          "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
        ];
      };
      gc = {
        automatic = true;
        interval = { Day = 7; };
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
