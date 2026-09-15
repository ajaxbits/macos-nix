# Secretive, a program to store SSH keys in the Secure Enclave.
{
  flake.aspects.secretive.darwin =
    { config, pkgs, ... }:
    let
      socket = "${config.macosNix.host.homeDirectory}/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh";
    in
    {
      environment.systemPackages = [ pkgs.secretive ];
      programs.ssh.extraConfig = ''
        Host *
          IdentityAgent ${socket}
      '';
      environment.variables.SSH_AUTH_SOCK = socket;
    };
}
