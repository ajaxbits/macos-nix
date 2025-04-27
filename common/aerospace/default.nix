{
  pkgs,
  ...
}:
{
  imports = [ ./settings ];
  services.aerospace = {
    enable = true;
    package = pkgs.aerospace;
  };
}
