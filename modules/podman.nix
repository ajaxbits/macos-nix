# Podman container engine (darwin aspect)
{ ... }:
{
  flake.modules.darwin.podman =
    { pkgs, lib, ... }:
    let
      inherit (lib) getExe;
      inherit (pkgs)
        podman
        podman-compose
        runCommand
        vfkit
        ;
    in
    {
      environment.systemPackages = [
        podman
        podman-compose
        vfkit

        # docker compat: symlink podman -> docker
        (runCommand "${podman.pname}-docker-compat-${podman.version}"
          {
            outputs = [ "out" "man" ];
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

        # docker-compose compat
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
