{ pkgs, ... }:
{
  nixpkgs.overlays = [
    (final: prev: {
      inherit (prev.lixPackageSets.stable)
        colmena
        nix-eval-jobs
        nix-fast-build
        nixpkgs-review
        ;
    })
  ];

  nix.package = pkgs.lixPackageSets.stable.lix;
}
