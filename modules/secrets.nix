# Agenix with age-plugin-se support and shared secret declarations.
{ inputs, ... }:
let
  # The pinned upstream module splits identity paths containing spaces in both
  # its preflight check and decryption loop (e.g. macOS Application Support).
  agenixHomeModule = builtins.toFile "agenix-home-quoted-identities.nix" (
    builtins.replaceStrings
      [
        "for identity in \${toString cfg.identityPaths}; do"
        "test -f \${path} ||"
        "# shellcheck disable=2043"
      ]
      [
        "for identity in \${lib.escapeShellArgs cfg.identityPaths}; do"
        "test -f \${lib.escapeShellArg path} ||"
        "# A configured identity list may contain just one path with spaces.\n    # shellcheck disable=SC2041,SC2043"
      ]
      (builtins.readFile inputs.agenix.homeManagerModules.default)
  );

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
  flake.aspects = {
    secrets = {
      darwin = {
        imports = [ inputs.agenix.darwinModules.default ];
      };
      homeManager =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        let
          pluginAge = pluginAgeFor pkgs;
          agenix = agenixFor pkgs;
        in
        {
          imports = [ agenixHomeModule ];

          age = {
            package = pluginAge;
            identityPaths = [ config.macosNix.host.ageIdentityPath ];
          };

          home.packages = [
            agenix
            pluginAge
            pkgs.age-plugin-se
          ];

          # The upstream module's inverse KeepAlive conditions cover every exit,
          # causing this successful one-shot agent to relaunch every ten seconds.
          launchd.agents.activate-agenix.config.KeepAlive = lib.mkForce false;
        };
    };

    shared-secrets.homeManager = {
      age.secrets.kagi_api_key.file = ../secrets/kagi_api_key.age;
    };

    work-shell-secrets.homeManager =
      { config, pkgs, ... }:
      let
        jfrog = import ../lib/jfrog-shell-env.nix { inherit pkgs; };
        shells = import ../lib/work-shell-secrets.nix {
          inherit pkgs;
          identityPath = config.macosNix.host.ageIdentityPath;
          secrets = {
            TF_TOKEN_app_terraform_io = ../secrets/terraform_cloud_token.age;
            JFROG_USERNAME = ../secrets/jfrog_username.age;
            JFROG_TOKEN = ../secrets/jfrog_token.age;
          };
          posixExtra = jfrog.posix;
          fishExtra = jfrog.fish;
        };
        shellEnv = "${shells}/share/work-shell-secrets/env.sh";
      in
      {
        home.packages = [ shells ];
        # These run for new shells regardless of the parent application's env.
        xdg.configFile."fish/conf.d/work-shell-secrets.fish".source =
          "${shells}/share/work-shell-secrets/env.fish";
        home.file = {
          ".zshenv".source = shellEnv;
          ".bashrc".source = shellEnv;
          ".bash_profile".source = shellEnv;
          ".profile".source = shellEnv;
        };
      };
  };

  perSystem =
    { pkgs, ... }:
    let
      pluginAge = pluginAgeFor pkgs;
      agenix = agenixFor pkgs;
      identityFixture = "/agenix-test/Library/Application Support/agenix/identity.txt";
      encryptedFixture = pkgs.writeText "agenix-test.age" "";
      jfrogFixture = import ../lib/jfrog-shell-env.nix { inherit pkgs; };
      tokenShellsFixture = import ../lib/work-shell-secrets.nix {
        inherit pkgs;
        identityPath = "/work-shell-secrets-test/Library/Application Support/agenix/identity.txt";
        secrets = {
          TF_TOKEN_app_terraform_io = "/work-shell-secrets-test/terraform token.age";
          JFROG_USERNAME = "/work-shell-secrets-test/jfrog username.age";
          JFROG_TOKEN = "/work-shell-secrets-test/jfrog token.age";
        };
        posixExtra = jfrogFixture.posix;
        fishExtra = jfrogFixture.fish;
      };
      testHome =
        identityPaths:
        inputs.home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            agenixHomeModule
            {
              home = {
                username = "agenix-test";
                homeDirectory = "/agenix-test";
                stateVersion = "26.05";
              };
              age = {
                package = pkgs.age;
                inherit identityPaths;
                secretsDir = "/agenix-test/secrets";
                secretsMountPoint = "/agenix-test/secrets.d";
                secrets.token.file = encryptedFixture;
              };
            }
          ];
        };
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

      checks = {
        agenix-identity-paths =
          pkgs.runCommand "agenix-identity-paths-test"
            {
              nativeBuildInputs = with pkgs; [
                age
                bash
                coreutils
                gnugrep
                shellcheck
              ];
            }
            ''
              identity="$PWD/Library/Application Support/agenix/identity.txt"
              mkdir -p "$(dirname "$identity")"
              age-keygen -o "$identity"
              printf 'test-token\n' > plaintext
              age --encrypt --recipient "$(age-keygen -y "$identity")" --output token.age plaintext

              substitute ${
                builtins.head
                  (testHome [ identityFixture ]).config.launchd.agents.activate-agenix.config.ProgramArguments
              } ./mount-secrets \
                --replace-fail '${encryptedFixture}' "$PWD/token.age" \
                --replace-fail '/agenix-test' "$PWD"
              shellcheck ./mount-secrets
              bash ./mount-secrets > output 2> errors
              test ! -s errors
              if grep -E 'no readable identities found|identity.txt not present' output; then
                exit 1
              fi
              cmp plaintext secrets/token
              test "$(stat --format=%a secrets/token)" = 400

              substitute ${
                builtins.head
                  (testHome [
                    "/agenix-test/missing identity"
                    identityFixture
                  ]).config.launchd.agents.activate-agenix.config.ProgramArguments
              } ./mount-secrets \
                --replace-fail '${encryptedFixture}' "$PWD/token.age" \
                --replace-fail '/agenix-test' "$PWD"
              shellcheck ./mount-secrets
              bash ./mount-secrets > output 2> errors
              test ! -s errors
              if grep -E 'no readable identities found|identity.txt not present' output; then
                exit 1
              fi
              cmp plaintext secrets/token
              test "$(readlink secrets)" = "$PWD/secrets.d/2"
              test ! -e secrets.d/1
              touch "$out"
            '';

        work-shell-secrets =
          pkgs.runCommand "work-shell-secrets-test"
            {
              nativeBuildInputs = with pkgs; [
                age
                bash
                coreutils
                fish
                gnused
                zsh
                shellcheck
              ];
            }
            ''
              cp ${../tests/work-shell-secrets.sh} ./test.sh
              shellcheck ./test.sh
              bash ./test.sh ${tokenShellsFixture} ${pkgs.fish}/bin/fish ${pkgs.zsh}/bin/zsh
              touch "$out"
            '';

        agenix-se-keygen =
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
    };
}
