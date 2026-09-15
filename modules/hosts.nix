# Host inventory and shared Darwin/Home Manager assembly.
{
  inputs,
  config,
  lib,
  ...
}:
let
  inherit (inputs.flake-aspects.lib lib) forward resolve;

  hosts = {
    Alexs-MacBook-Air = {
      outputName = "Alexs-MacBook-Air";
      hostName = "Alexs-MacBook-Air";
      profile = "personal";
      system = "aarch64-darwin";
      userName = "ajax";
      fullName = "Alex Jackson";
      homeDirectory = "/Users/ajax";
      uid = 501;
      manageUser = true;
      nixTrustedUser = true;
      darwinStateVersion = 5;
      homeStateVersion = "22.05";
      homeManagerBackupExtension = "bak";
      gitName = "Alex Jackson";
      gitEmail = "git@ajaxbits.com";
      # Retained until this device is enrolled with a Secure Enclave recipient.
      ageIdentityPath = "/Users/ajax/.ssh/bitwarden";
      ageIdentityType = "legacy-ssh";
      flakeDirectory = "/Users/ajax/code/macos-nix";
      synthetic = false;
      deploymentReady = true;
    };

    K1H96QD74C = {
      outputName = "K1H96QD74C";
      hostName = "K1H96QD74C";
      profile = "work";
      system = "aarch64-darwin";
      userName = "alexander.jackson";
      fullName = "Alex Jackson";
      homeDirectory = "/Users/alexander.jackson";
      uid = 502;
      manageUser = false;
      nixTrustedUser = true;
      darwinStateVersion = 7;
      homeStateVersion = "26.05";
      homeManagerBackupExtension = null;
      gitName = "Alex Jackson";
      gitEmail = "alexander.jackson@upside.com";
      ageIdentityPath = "/Users/alexander.jackson/Library/Application Support/agenix/identity.txt";
      ageIdentityType = "secure-enclave";
      flakeDirectory = "/Users/alexander.jackson/code/macos-nix";
      synthetic = false;
      deploymentReady = true;
    };
  };

  hasPlaceholderIdentity =
    host:
    host.gitName == ""
    || host.gitEmail == ""
    || lib.hasInfix "FIXME" host.gitName
    || lib.hasInfix "FIXME" host.gitEmail
    || lib.hasPrefix "Synthetic " host.gitName
    || lib.hasSuffix ".invalid" host.gitEmail
    || lib.hasSuffix "@work.example.com" host.gitEmail;

  hasEmptyRequiredFact =
    host:
    lib.any (value: value == "") [
      host.outputName
      host.hostName
      host.userName
      host.homeDirectory
      host.ageIdentityPath
      host.flakeDirectory
    ];

  validateHost =
    host:
    if hasEmptyRequiredFact host then
      throw "host output, hostname, username, home, and flake directory must be non-empty"
    else if !(builtins.hasAttr host.profile config.flake.aspects) then
      throw "host ${host.outputName} selects unknown profile aspect ${host.profile}"
    else if host.profile == "work" && !host.synthetic && hasPlaceholderIdentity host then
      throw "real work host ${host.outputName} requires an explicit Git/jj identity"
    else
      host;

  validateInventory =
    inventory:
    if lib.all (name: name == inventory.${name}.outputName) (builtins.attrNames inventory) then
      inventory
    else
      throw "host inventory keys must match their outputName";

  mkDarwinConfiguration =
    uncheckedHost:
    let
      host = validateHost uncheckedHost;
      profile = config.flake.aspects.${host.profile};
      hostAspect = {
        includes = [
          profile
          (forward {
            each = [ host ];
            fromClass = _: "homeManager";
            intoClass = _: "darwin";
            intoPath = value: [
              "home-manager"
              "users"
              value.userName
            ];
            fromAspect = _: profile;
          })
        ];

        darwin = {
          imports = [ inputs.home-manager.darwinModules.home-manager ];

          macosNix.host = host;
          networking.hostName = host.hostName;

          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = host.homeManagerBackupExtension;
            users.${host.userName}.macosNix.host = host;
          };
        };
      };
    in
    inputs.darwin.lib.darwinSystem {
      inherit (host) system;
      modules = [ (resolve "darwin" [ ] hostAspect) ];
    };
in
{
  options.macosNix.mkDarwinConfiguration = lib.mkOption {
    type = lib.types.raw;
    readOnly = true;
  };
  options.macosNix.hosts = lib.mkOption {
    type = lib.types.raw;
    readOnly = true;
  };

  config = {
    macosNix.hosts = validateInventory hosts;
    macosNix.mkDarwinConfiguration = mkDarwinConfiguration;
    flake.darwinConfigurations = builtins.mapAttrs (_: mkDarwinConfiguration) (
      lib.filterAttrs (_: host: host.deploymentReady) (validateInventory hosts)
    );
  };
}
