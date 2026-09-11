{ inputs, ... }:
{
  flake.modules.darwin.secrets = {
    imports = [ inputs.agenix.darwinModules.default ];
  };

  flake.modules.homeManager.secrets =
    { config, ... }:
    {
      imports = [ inputs.agenix.homeManagerModules.default ];

      age = {
        identityPaths = [ "${config.home.homeDirectory}/.ssh/bitwarden" ];
        secrets = {
          kagi_api_key.file = ../secrets/kagi_api_key.age;
        };
      };
    };
}
