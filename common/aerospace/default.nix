{ pkgsUnstable, user, ... }:
{
  services.aerospace = {
    enable = true;
    package = pkgsUnstable.aerospace;
  };
  environment.etc."/home/${user}/aerospace.toml".source = ./aerospace.toml;
}
