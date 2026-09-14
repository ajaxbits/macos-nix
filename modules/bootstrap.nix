# First-switch bootstrap application. Importing this module never activates it.
{ inputs, config, ... }:
let
  inherit (config.macosNix)
    hosts
    mkDarwinConfiguration
    ;
in
{
  perSystem =
    { config, pkgs, ... }:
    let
      inherit (pkgs.stdenv.hostPlatform) system;
      inherit (pkgs.lixPackageSets.latest) lix;

      secretBaseName =
        path:
        let
          base = builtins.baseNameOf (toString path);
          storeMatch = builtins.match "[0-9abcdfghijklmnpqrsvwxyz]{32}-(.*\\.age)" base;
        in
        if storeMatch == null then base else builtins.head storeMatch;
      secretFilesFor =
        host:
        let
          darwin = mkDarwinConfiguration host;
          home = darwin.config.home-manager.users.${host.userName};
          files = map (secret: secretBaseName secret.file) (builtins.attrValues home.age.secrets);
        in
        if builtins.length files != builtins.length (pkgs.lib.unique files) then
          throw "host ${host.outputName} has age secrets with duplicate ciphertext basenames"
        else
          files;
      hostsFile = pkgs.writeText "macos-nix-bootstrap-hosts.json" (
        builtins.toJSON (builtins.mapAttrs (_: host: host // { secretFiles = secretFilesFor host; }) hosts)
      );
      homebrewInstaller = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/Homebrew/install/8949852f785a3bacaba2a979d0790337950b0a4a/install.sh";
        hash = "sha256-JVSOHaeTDBVj274ssFg0pBMcTaCSNFQLb9rIEv2jwoc=";
      };
      bootstrap = pkgs.writeShellApplication {
        name = "macos-nix-bootstrap";
        runtimeInputs = [
          pkgs.bash
          pkgs.coreutils
          pkgs.gnugrep
          pkgs.gnused
          pkgs.jq
          lix
        ];
        text = ''
          export BOOTSTRAP_HOSTS_FILE=${hostsFile}
          export NIX=${lix}/bin/nix
          export AGENIX=${config.packages.agenix}/bin/agenix
          export AGE_PLUGIN_SE=${pkgs.age-plugin-se}/bin/age-plugin-se
          export AGENIX_SE_KEYGEN=${config.packages.agenix-se-keygen}/bin/agenix-se-keygen
          export DARWIN_REBUILD=${inputs.darwin.packages.${system}.darwin-rebuild}/bin/darwin-rebuild
          export HOMEBREW_INSTALLER=${homebrewInstaller}
          unset ID UNAME SCUTIL XCODE_SELECT SUDO BREW SYSTEM_NIX SYSTEM_DARWIN_REBUILD STAT DSCL INTEL_BREW SYSTEM_PROFILE
          exec ${pkgs.bash}/bin/bash ${../scripts/bootstrap.sh} "$@"
        '';
      };
    in
    {
      packages.bootstrap = bootstrap;
      apps.bootstrap = {
        type = "app";
        program = "${bootstrap}/bin/macos-nix-bootstrap";
      };

      checks.bootstrap =
        assert secretBaseName "github-token.age" == "github-token.age";
        assert
          secretBaseName "/nix/store/00000000000000000000000000000000-github-token.age" == "github-token.age";
        pkgs.runCommand "macos-nix-bootstrap-test"
          {
            nativeBuildInputs = with pkgs; [
              bash
              coreutils
              gnugrep
              jq
              shellcheck
            ];
          }
          ''
            cp ${../scripts/bootstrap.sh} ./bootstrap.sh
            cp ${../tests/bootstrap.sh} ./test.sh
            chmod +x ./*.sh
            patchShebangs ./*.sh
            shellcheck ./*.sh
            ./test.sh ./bootstrap.sh
            touch "$out"
          '';
    };
}
