{
  description = "Macos Nix Machines";

  inputs = {
    # Package sets
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Meta
    lix-module = {
      url = "https://git.lix.systems/lix-project/nixos-module/archive/2.92.0-3.tar.gz";
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
      systems = [ "aarch64-darwin" ];
      flake.darwinConfigurations =
        let
          inherit (inputs.darwin.lib) darwinSystem;
          system = "aarch64-darwin";
          user = "ajax";
          hostname = "Alexs-MacBook-Air";

          # Configuration for `nixpkgs`
          nixpkgs = {
            overlays = [ inputs.nur.overlays.default ];
            config = {
              allowBroken = true;
              allowUnfree = true;
            };
          };

          specialArgs = {
            inherit
              hostname
              inputs
              self
              user
              ;
          };
        in
        {
          ${hostname} = darwinSystem {
            inherit specialArgs system;
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
