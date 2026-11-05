# SSH client settings shared by every profile.
{
  flake.aspects.ssh.darwin = {
    programs.ssh.extraConfig = ''
      Host *
        ControlMaster auto
        ControlPath ~/.ssh/cm-%C
        ControlPersist 10m
    '';
  };
}
