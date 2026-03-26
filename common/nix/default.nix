{ pkgs, ... }:
let
  lixPackageSet = pkgs.lixPackageSets.latest;
in
{
  nixpkgs.overlays = [
    (_: _: {
      inherit (lixPackageSet)
        colmena
        nil
        nix-direnv
        nix-eval-jobs
        nix-fast-build
        nixpkgs-review
        nixpkgs-reviewFull
        nurl
        ;
    })
  ];

  nix.package = lixPackageSet.lix;
}
