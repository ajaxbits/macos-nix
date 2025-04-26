{
  pkgs,
  ...
}:
{
  services.aerospace = {
    enable = true;
    package = pkgs.aerospace; # TODO: enable pkgsUnstable eventually
    settings = import ./settings;
  };
}
