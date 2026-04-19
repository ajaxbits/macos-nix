# Secretive, a program to store ssh keys in the TPM
let
  userName = "ajax";
in
{
  flake.modules.darwin.secretive =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.secretive ];
      programs.ssh.extraConfig = ''
        Host *
        	IdentityAgent /Users/${userName}/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh
      '';
      environment.variables.SSH_AUTH_SOCK = "/Users/${userName}/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh";
    };
}
