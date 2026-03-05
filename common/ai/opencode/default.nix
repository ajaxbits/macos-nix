{ pkgs, lib, config, ... }:
let
  inherit (lib) getExe' mkEnableOption mkIf mkOption mkPackageOption types;
  cfg = config.components.opencode;
  uvx = getExe' pkgs.uv "uvx";
in
{
  options.components.opencode = {
    enable = mkEnableOption "opencode AI coding assistant";
    package = mkPackageOption pkgs "opencode" { };
    kagiApiKeyFile = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Runtime path to a file containing the Kagi API key. When null, web search via the Kagi MCP server will not work.";
    };
  };

  config = mkIf cfg.enable {
    warnings = lib.optional (cfg.kagiApiKeyFile == null)
      "components.opencode: kagiApiKeyFile is not set. OpenCode's web search feature (Kagi MCP) will not work without it.";

    programs.opencode = {
      enable = true;
      package = cfg.package;
      rules = ./AGENTS.md;
      enableMcpIntegration = true;
      settings = {
        theme = "system";
        permission.websearch = "deny"; # handled by kagi mcp
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

    home.sessionVariables.OPENCODE_EXPERIMENTAL = "true";

    programs.fish.interactiveShellInit = mkIf (cfg.kagiApiKeyFile != null) ''
      if test -r ${cfg.kagiApiKeyFile}
        set -gx KAGI_API_KEY (string trim (cat ${cfg.kagiApiKeyFile}))
      end
    '';
  };
}
