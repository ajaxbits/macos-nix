# Quick capture to Todoist: `todo` queues a note and launchd drains the queue
# through a headless omp run. Work only.
{ lib, ... }:
{
  flake.aspects.todoist-capture.homeManager =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      stateDir = "${config.home.homeDirectory}/.local/state/todoist-capture";
      logPrefix = "${config.home.homeDirectory}/Library/Logs/todoist-capture";
      # Print mode refuses any tool that needs approval, so this allowlist is
      # everything a pasted note can make omp do.
      ompConfig = pkgs.writeText "todoist-capture-omp.yml" ''
        tools:
          xdev: false
          approval:
            mcp__todoist_add_tasks: allow
        memory:
          backend: "off"
        autolearn:
          enabled: false
      '';
      mkCommand =
        name: action:
        pkgs.writeShellApplication {
          inherit name;
          runtimeInputs = [
            pkgs.bash
            pkgs.coreutils
            pkgs.gnugrep
            pkgs.gnused
          ];
          text = ''
            export OMP="''${OMP:-${pkgs.llm-agents.omp}/bin/omp}"
            export TODOIST_CAPTURE_CONFIG=${ompConfig}
            exec ${lib.getExe pkgs.bash} ${../scripts/todoist-capture.sh} ${action} "$@"
          '';
        };
      todo = mkCommand "todo" "add";
      drain = mkCommand "todoist-capture-drain" "drain";
    in
    {
      home.packages = [ todo ];

      # launchd must find the queue directory when it loads the agent.
      home.activation.todoistCaptureQueue =
        lib.hm.dag.entryBetween [ "setupLaunchAgents" ] [ "writeBoundary" ]
          ''
            run mkdir -p ${lib.escapeShellArg "${stateDir}/inbox"}
          '';

      launchd.agents.todoist-capture = {
        enable = true;
        config = {
          ProgramArguments = [ (lib.getExe drain) ];
          QueueDirectories = [ "${stateDir}/inbox" ];
          RunAtLoad = true;
          StandardOutPath = "${logPrefix}.out.log";
          StandardErrorPath = "${logPrefix}.err.log";
        };
      };
    };

  perSystem =
    { pkgs, ... }:
    {
      checks.todoist-capture =
        pkgs.runCommand "todoist-capture-test"
          {
            nativeBuildInputs = with pkgs; [
              bash
              coreutils
              findutils
              gnugrep
              gnused
              shellcheck
            ];
          }
          ''
            cp ${../scripts/todoist-capture.sh} ./todoist-capture.sh
            cp ${../tests/todoist-capture.sh} ./test.sh
            chmod +x ./*.sh
            patchShebangs ./*.sh
            shellcheck ./*.sh
            ./test.sh ./todoist-capture.sh
            touch "$out"
          '';
    };
}
