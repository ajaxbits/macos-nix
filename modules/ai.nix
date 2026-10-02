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
        darwin.homebrew = {
          enable = true;
          enableBashIntegration = true;
          enableFishIntegration = true;
          enableZshIntegration = true;

          casks = [ "claude" ];
          brews = [
            {
              name = "ollama";
              restart_service = "changed";
            }
          ];
        };
        homeManager =
          { pkgs, ... }:
          {
            home = {
              packages = [ pkgs.claude-code ];
              # brew reads $HOMEBREW_USER_CONFIG_HOME, which is ~/.homebrew when XDG_CONFIG_HOME is unset.
              file.".homebrew/services/ollama.env".text = ''
                OLLAMA_HOST=[::]
              '';
            };
          };
      };
    };
}
