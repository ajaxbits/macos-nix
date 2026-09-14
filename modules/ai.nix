# AI coding tool installation only; each tool owns its runtime configuration.
{ inputs, ... }:
{
  flake.modules = {
    darwin = {
      ai-base = {
        nixpkgs.overlays = [ inputs.llm-agents.overlays.shared-nixpkgs ];
      };
      ai-work = {
        homebrew.casks = [ "claude" ];
      };
    };

    homeManager = {
      ai-base =
        { pkgs, ... }:
        {
          home.packages = [ pkgs.llm-agents.opencode2 ];
        };
      ai-personal = { };
      ai-work =
        { pkgs, ... }:
        {
          home.packages = [
            pkgs.claude-code
          ];
        };
    };
  };
}
