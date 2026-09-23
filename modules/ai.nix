# AI coding tool installation only; each tool owns its runtime configuration.
{ inputs, ... }:
{
  flake.aspects =
    { aspects, ... }:
    {
      ai-base = {
        darwin.nixpkgs.overlays = [ inputs.llm-agents.overlays.shared-nixpkgs ];
        homeManager =
          { pkgs, ... }:
          {
            home.packages = with pkgs.llm-agents; [
              omp
              opencode2
            ];
          };
      };

      ai-personal.homeManager = { };

      ai-work = {
        includes = [ aspects.opencode-upside-sync ];
        darwin.homebrew.casks = [ "claude" ];
        homeManager =
          { pkgs, ... }:
          {
            home.packages = [ pkgs.claude-code ];
          };
      };
    };
}
