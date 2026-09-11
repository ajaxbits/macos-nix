# Host inventory and shared Darwin/Home Manager assembly.
{
  inputs,
  config,
  lib,
  ...
}:
let
  hosts.Alexs-MacBook-Air = {
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
    gitName = "Alex Jackson";
    gitEmail = "git@ajaxbits.com";
    flakeDirectory = "/Users/ajax/code/macos-nix";
    synthetic = false;
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
      host.flakeDirectory
    ];

  validateHost =
    host:
    if hasEmptyRequiredFact host then
      throw "host output, hostname, username, home, and flake directory must be non-empty"
    else if host.profile == "work" && !host.synthetic && hasPlaceholderIdentity host then
      throw "real work host ${host.outputName} requires an explicit Git/jj identity"
    else
      host;

  mkDarwinConfiguration =
    uncheckedHost:
    let
      host = validateHost uncheckedHost;
      darwinProfile = config.flake.modules.darwin.${host.profile};
      homeProfile = config.flake.modules.homeManager.${host.profile};
    in
    inputs.darwin.lib.darwinSystem {
      modules = [
        {
          macosNix.host = host;
          networking.hostName = host.hostName;
        }
        darwinProfile
        inputs.home-manager.darwinModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "bak";
            users.${host.userName}.imports = [
              { macosNix.host = host; }
              homeProfile
            ];
          };
        }
      ];
    };
in
{
  options.macosNix.mkDarwinConfiguration = lib.mkOption {
    type = lib.types.raw;
    readOnly = true;
  };

  config = {
    macosNix.mkDarwinConfiguration = mkDarwinConfiguration;
    flake.darwinConfigurations = builtins.mapAttrs (_: mkDarwinConfiguration) hosts;
  };
}
