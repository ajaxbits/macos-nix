# Agenix with age-plugin-se support and shared secret declarations.
{ inputs, ... }:
let
  pluginAgeFor =
    pkgs:
    pkgs.writeShellScriptBin "age" ''
      export PATH=${pkgs.age-plugin-se}/bin:$PATH
      exec ${pkgs.age}/bin/age "$@"
    '';

  agenixFor =
    pkgs:
    inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default.override {
      ageBin = "${pluginAgeFor pkgs}/bin/age";
    };
in
{
  flake.modules = {
    darwin.secrets = {
      imports = [ inputs.agenix.darwinModules.default ];
    };
    homeManager = {
      secrets =
        { config, pkgs, ... }:
        let
          pluginAge = pluginAgeFor pkgs;
          agenix = agenixFor pkgs;
        in
        {
          imports = [ inputs.agenix.homeManagerModules.default ];

          age = {
            package = pluginAge;
            identityPaths = [ config.macosNix.host.ageIdentityPath ];
          };

          home.packages = [
            agenix
            pluginAge
            pkgs.age-plugin-se
          ];
        };

      shared-secrets = {
        age.secrets.kagi_api_key.file = ../secrets/kagi_api_key.age;
      };
    };
  };

  perSystem =
    { pkgs, ... }:
    let
      pluginAge = pluginAgeFor pkgs;
      agenix = agenixFor pkgs;
      keygen = pkgs.writeShellApplication {
        name = "agenix-se-keygen";
        runtimeInputs = with pkgs; [
          coreutils
          gnugrep
          gnused
        ];
        text = ''
          export AGE_PLUGIN_SE=${pkgs.age-plugin-se}/bin/age-plugin-se
          exec ${pkgs.bash}/bin/bash ${../scripts/agenix-se-keygen.sh} "$@"
        '';
      };
    in
    {
      packages = {
        inherit agenix;
        inherit (pkgs) age-plugin-se;
        age-secure-enclave = pluginAge;
        agenix-se-keygen = keygen;
      };

      checks.agenix-se-keygen =
        pkgs.runCommand "agenix-se-keygen-test"
          {
            nativeBuildInputs = with pkgs; [
              bash
              coreutils
              shellcheck
            ];
          }
          ''
            cp ${../scripts/agenix-se-keygen.sh} ./agenix-se-keygen.sh
            cp ${../tests/agenix-se-keygen.sh} ./test.sh
            chmod +x ./*.sh
            patchShebangs ./*.sh
            shellcheck ./*.sh
            ./test.sh ./agenix-se-keygen.sh
            touch "$out"
          '';
    };
}
