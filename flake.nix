{
  description = "Macos Nix Machines";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";

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
    llm-agents.url = "github:numtide/llm-agents.nix";
    nur.url = "github:nix-community/NUR";
  };

  outputs =
    inputs:
    inputs.parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);

  nixConfig = {
    extra-substituters = [
      "https://cache.nix.ajax.casa/patroclus?priority=10"
      "https://cache.garnix.io"
      "https://cache.numtide.com"
    ];

    extra-trusted-public-keys = [
      "patroclus:Qy1DbSYS2lL+DDxXY+e0C4ryF7COHyf6LN4g4OtcbW4="
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };
}
