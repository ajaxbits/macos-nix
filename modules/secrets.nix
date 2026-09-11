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
  flake.modules.darwin.secrets = {
    imports = [ inputs.agenix.darwinModules.default ];
  };

  flake.modules.homeManager.secrets =
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

  flake.modules.homeManager.shared-secrets = {
    age.secrets.kagi_api_key.file = ../secrets/kagi_api_key.age;
  };

  perSystem =
    { pkgs, ... }:
    let
      pluginAge = pluginAgeFor pkgs;
      agenix = agenixFor pkgs;
      keygen = pkgs.writeShellApplication {
        name = "agenix-se-keygen";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.gnugrep
          pkgs.gnused
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
        age-secure-enclave = pluginAge;
        age-plugin-se = pkgs.age-plugin-se;
        agenix-se-keygen = keygen;
      };

      checks.agenix-se-keygen =
        pkgs.runCommand "agenix-se-keygen-test"
          {
            nativeBuildInputs = [
              pkgs.bash
              pkgs.coreutils
              pkgs.shellcheck
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
