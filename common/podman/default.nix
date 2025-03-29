# Yoinked from https://github.com/ToyVo/nixcfg/blob/6c0f6351c32ef1a38fdb0ef48ff153e661014ee0/modules/darwin/podman.nix
{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib)
    getExe
    mkEnableOption
    mkIf
    optionals
    ;
  inherit (pkgs)
    podman
    podman-compose
    runCommand
    vfkit
    ;
  cfg = config.virtualisation.podman;
in
{
  options.virtualisation.podman = {
    enable = mkEnableOption "This option enables Podman, a daemonless container engine for developing, managing, and running OCI Containers on your System.";
    compose.enable = mkEnableOption "Enable podman-compose.";
    dockerCompat = mkEnableOption "Create an alias mapping docker commands to podman.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages =
      [
        podman
        vfkit
      ]
      ++ optionals cfg.compose.enable [ podman-compose ]
      ++ optionals cfg.dockerCompat [
        (runCommand "${podman.pname}-docker-compat-${podman.version}"
          {
            outputs = [
              "out"
              "man"
            ];
            inherit (podman) meta;
          }
          ''
            mkdir -p $out/bin
            ln -s ${getExe podman} $out/bin/docker

            mkdir -p $man/share/man/man1
            for f in ${podman.man}/share/man/man1/*; do
              basename=$(basename $f | sed s/podman/docker/g)
              ln -s $f $man/share/man/man1/$basename
            done
          ''
        )
      ]
      ++ optionals (cfg.dockerCompat && cfg.compose.enable) [
        (runCommand "${podman-compose.pname}-docker-compat-${podman-compose.version}"
          {
            outputs = [ "out" ];
            inherit (podman-compose) meta;
          }
          ''
            mkdir -p $out/bin
            ln -s ${getExe podman-compose} $out/bin/docker-compose
          ''
        )
      ];
  };
}
