# OpenCode runtime support for Upside's internal skill marketplace. Work only.
{ lib, ... }:
let
  marketplace = "upside-official";
  marketplaceSource = "upside-services/ai-marketplace";
  upsidePlugins = [
    "agent-platform"
    "aws-access"
    "aws-platform"
    "data-eng-ai-utils"
    "hooks"
    "internal-documentation"
    "pay-ai-utils"
    "prodsec"
    "sdlc"
    "superpowers"
  ];

  mkUpsideCommand =
    pkgs: name: action:
    pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = [
        pkgs.bash
        pkgs.claude-code
        pkgs.coreutils
        pkgs.git
        pkgs.jq
        pkgs.openssh
      ];
      text = ''
        export UPSIDE_MARKETPLACE=${lib.escapeShellArg marketplace}
        export UPSIDE_MARKETPLACE_SOURCE=${lib.escapeShellArg marketplaceSource}
        export UPSIDE_PLUGINS_JSON=${lib.escapeShellArg (builtins.toJSON upsidePlugins)}
        export CLAUDE_PLUGIN_CLI="''${CLAUDE_PLUGIN_CLI:-${lib.getExe pkgs.claude-code}}"
        export JQ="''${JQ:-${lib.getExe pkgs.jq}}"
        export SSH="''${SSH:-${lib.getExe' pkgs.openssh "ssh"}}"
        export TIMEOUT="''${TIMEOUT:-${lib.getExe' pkgs.coreutils "timeout"}}"
        exec ${lib.getExe pkgs.bash} ${../scripts/opencode-upside-skills.sh} ${action} "$@"
      '';
    };
in
{
  flake.aspects.opencode-upside-sync.homeManager =
    {
      config,
      pkgs,
      ...
    }:
    let
      updateUpsidePlugins = mkUpsideCommand pkgs "claude-update-upside-plugins" "update";
      syncUpsideSkills = mkUpsideCommand pkgs "opencode-sync-upside-skills" "sync";
      refreshUpsideSkills = mkUpsideCommand pkgs "opencode-refresh-upside-skills" "refresh";
      logPrefix = "${config.home.homeDirectory}/Library/Logs/opencode-upside-sync";
    in
    {
      home.packages = [
        updateUpsidePlugins
        syncUpsideSkills
        refreshUpsideSkills
      ];

      # Keep Nix's declared plugin set installed and current, then publish each
      # skills/ directory where OpenCode discovers global skills automatically.
      launchd.agents.opencode-upside-sync = {
        enable = true;
        config = {
          ProgramArguments = [ (lib.getExe refreshUpsideSkills) ];
          RunAtLoad = true;
          StartInterval = 3600;
          StandardOutPath = "${logPrefix}.out.log";
          StandardErrorPath = "${logPrefix}.err.log";
        };
      };
    };

  perSystem =
    { pkgs, ... }:
    {
      checks.opencode-upside-skills =
        pkgs.runCommand "opencode-upside-skills-test"
          {
            nativeBuildInputs = with pkgs; [
              bash
              coreutils
              gnugrep
              jq
              shellcheck
            ];
          }
          ''
            cp ${../scripts/opencode-upside-skills.sh} ./opencode-upside-skills.sh
            cp ${../tests/opencode-upside-skills.sh} ./test.sh
            chmod +x ./*.sh
            patchShebangs ./*.sh
            shellcheck ./*.sh
            ./test.sh ./opencode-upside-skills.sh
            touch "$out"
          '';
    };
}
