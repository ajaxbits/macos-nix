{
  inputs,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) getExe';
  opencode-pkg = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.opencode;
  uvx = getExe' pkgs.uv "uvx";
in
{
  programs = {
    opencode = {
      enable = true;
      package = opencode-pkg;

      rules = ./AGENTS.md;
      enableMcpIntegration = true;

      settings = {
        theme = "system";
        permission = {
          websearch = "deny"; # handled by kagi mcp
        };
      };
    };

    mcp = {
      enable = true;
      servers.kagi = {
        command = uvx;
        args = [ "kagimcp" ];
        environment.KAGI_API_KEY = "{env:KAGI_API_KEY}";
      };
    };
  };
  home.sessionVariables.OPENCODE_EXPERIMENTAL = "true";
}
