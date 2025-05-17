{
  description = "Macos Nix Machines";

  inputs = {
    # Package sets
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Meta
    lix-module = {
      url = "https://git.lix.systems/lix-project/nixos-module/archive/2.93.0.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    parts.url = "github:hercules-ci/flake-parts";

    # System
    darwin = {
      url = "github:lnl7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix.url = "github:ryantm/agenix";
    nvim.url = "github:ajaxbits/nvim";
    nur.url = "github:nix-community/NUR";
  };

  outputs =
    {
      self,
      darwin,
      lix-module,
      parts,
      ...
    }@inputs:
    parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.home-manager.flakeModules.home-manager
      ];
      systems = [
        "aarch64-darwin"
      ];

      flake.darwinConfigurations =
        let
          inherit (inputs.darwin.lib) darwinSystem;
          user = "ajax";
          macbookAir = "Alexs-MacBook-Air";

          # Configuration for `nixpkgs`
          nixpkgs = {
            config = {
              allowBroken = true;
              allowUnfree = true;
            };
            hostPlatform = "aarch64-darwin";
            overlays = [ inputs.nur.overlays.default ];
          };

          specialArgs = {
            inherit
              inputs
              self
              user
              ;

            hostname = macbookAir;
            system = nixpkgs.hostPlatform;
          };
        in
        {
          ${macbookAir} = darwinSystem {
            inherit specialArgs;

            modules = [
              # Base
              lix-module.nixosModules.default

              # Main `nix-darwin` config
              ./hosts/aphrodite

              # home-manager
              inputs.home-manager.darwinModules.home-manager
              {
                inherit nixpkgs;
                home-manager = {
                  useGlobalPkgs = true;
                  useUserPackages = true;
                  extraSpecialArgs = specialArgs;

                  users."ajax" =
                    { ... }:
                    {
                      imports = [ "${self}/hosts/aphrodite/home.nix" ];
                    };
                };
              }

              # secrets
              inputs.agenix.darwinModules.default

              # other modules
              "${self}/common/podman"

              #
              {
                environment.systemPackages = [ inputs.nvim.packages.aarch64-darwin.default ];
              }
            ];
          };
        };
    };

  nixConfig = {
    extra-substituters = [
      "https://cache.garnix.io"
      "https://cache.lix.systems"
    ];

    extra-trusted-public-keys = [
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      "cache.lix.systems:aBnZUw8zA7H35Cz2RyKFVs3H4PlGTLawyY5KRbvJR8o="
    ];
  };
}
