# OpenCode AI coding assistant (homeManager + darwin aspects)
{ inputs, ... }:
{
  # Add llm-agents overlay so pkgs.opencode comes from numtide
  flake.modules.darwin.opencode = {
    nixpkgs.overlays = [ inputs.llm-agents.overlays.default ];
  };

  flake.modules.homeManager.opencode =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      uvx = lib.getExe' pkgs.uv "uvx";
      kagiApiKeyFile = config.age.secrets.kagi_api_key.path;
    in
    {
      programs.opencode = {
        enable = true;
        package = pkgs.opencode;
        context = ./opencode/AGENTS.md;
        enableMcpIntegration = true;
        settings = {
          permission.websearch = "deny";
        };
        tui = {
          theme = "system";
        };
      };

      programs.mcp = {
        enable = true;
        servers.kagi = {
          command = uvx;
          args = [ "kagimcp" ];
          environment.KAGI_API_KEY = "{env:KAGI_API_KEY}";
        };
      };

      programs.fish.interactiveShellInit = ''
        if test -r ${kagiApiKeyFile}
          set -gx KAGI_API_KEY (string trim (cat ${kagiApiKeyFile}))
        end
      '';

      home.sessionVariables.OPENCODE_EXPERIMENTAL = "true";
    };
}
