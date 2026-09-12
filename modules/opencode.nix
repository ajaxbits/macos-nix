# OpenCode V2 package installation only; OpenCode owns its runtime configuration.
{ inputs, ... }:
{
  flake.modules.darwin.opencode = {
    nixpkgs.overlays = [ inputs.llm-agents.overlays.shared-nixpkgs ];
  };

  flake.modules.homeManager.opencode = { pkgs, ... }: {
    home.packages = [ pkgs.llm-agents.opencode2 ];
  };
}
