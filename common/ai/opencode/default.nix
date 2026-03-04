{ pkgs, lib, ... }:
let
  inherit (lib) getExe';
  uvx = getExe' pkgs.uv "uvx";
in
{
  programs = {
    opencode = {
      enable = true;

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
