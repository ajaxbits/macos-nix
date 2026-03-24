# Host wiring: assemble darwinConfigurations from aspects
{ inputs, config, ... }:
let
  macbookAir = "Alexs-MacBook-Air";
  user = "ajax";
in
{
  flake.darwinConfigurations.${macbookAir} = inputs.darwin.lib.darwinSystem {
    modules =
      [
        { networking.hostName = macbookAir; }

        inputs.home-manager.darwinModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "bak";
            users.${user}.imports = builtins.attrValues config.flake.modules.homeManager;
          };
        }
      ]
      ++ builtins.attrValues config.flake.modules.darwin;
  };
}
