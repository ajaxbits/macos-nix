{ inputs, ... }:
let
  userName = "ajax";
in
{
  flake.modules.darwin.secrets = {
    imports = [ inputs.agenix.darwinModules.default ];
  };

  flake.modules.homeManager.secrets =
    { ... }:
    {
      imports = [ inputs.agenix.homeManagerModules.default ];

      age = {
        identityPaths = [ "/Users/${userName}/.ssh/bitwarden" ];
        secrets = {
          kagi_api_key.file = ../secrets/kagi_api_key.age;
        };
      };
    };
}
