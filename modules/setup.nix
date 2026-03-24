# The "setup" module: flake-parts plumbing that every other module relies on.
# Enables the flake.modules option and sets the system list.
{ inputs, ... }:
{
  imports = [
    inputs.parts.flakeModules.modules
    inputs.home-manager.flakeModules.home-manager
  ];

  systems = [ "aarch64-darwin" ];
}
