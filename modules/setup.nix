# The "setup" module: flake-parts plumbing that every other module relies on.
# Enables the flake module/aspect options and sets the system list.
{ inputs, ... }:
{
  imports = [
    inputs.parts.flakeModules.modules
    inputs.flake-aspects.flakeModule
    inputs.home-manager.flakeModules.home-manager
  ];

  systems = [ "aarch64-darwin" ];
}
