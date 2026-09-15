# AI coding tool installation only; each tool owns its runtime configuration.
{ inputs, ... }:
{
  flake.aspects = {
    ai-base = {
      darwin.nixpkgs.overlays = [ inputs.llm-agents.overlays.shared-nixpkgs ];
      homeManager =
        { pkgs, ... }:
        {
          home.packages = [ pkgs.llm-agents.opencode2 ];
        };
    };

    ai-personal.homeManager = { };

    ai-work = {
      darwin.homebrew.casks = [ "claude" ];
      homeManager =
        { pkgs, ... }:
        {
          home.packages = [ pkgs.claude-code ];
        };
    };
  };
}
