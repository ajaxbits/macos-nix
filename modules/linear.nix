# Linear desktop app. "Work on issue → Custom script" opens omp on the issue in a new Rex session.
# https://linear.app/docs/open-issues-with-custom-scripts
{
  flake.aspects.linear-work = {
    darwin.homebrew.casks = [ "linear" ];

    homeManager =
      { pkgs, ... }:
      let
        jq = "${pkgs.jq}/bin/jq";
        openIssue = pkgs.writeShellScript "linear-open-issue" ''
          set -eu
          # Linear runs this from the GUI with a bare PATH, so call rex by its stable install path.
          rex="$HOME/Library/Application Support/com.superlogical.rex/RexServer/Versions/Current/Rex Server.app/Contents/MacOS/rex"
          label=$(printf '%s' "''${LINEAR_ISSUE_IDENTIFIER:-linear-issue}" | tr '[:upper:]' '[:lower:]')
          set -- omp
          if [ -n "''${LINEAR_PROMPT:-}" ]; then set -- omp "$LINEAR_PROMPT"; fi
          # --interactive loads fish's interactive config, so omp gets the usual PATH and secrets.
          session=$("$rex" new "$label" -c "''${LINEAR_WORK_DIR:-$HOME}" --interactive --json -- "$@" | ${jq} -r .session_id)
          # Bring it up in the Rex app. Needs Remote Control; without it the session still exists.
          client=$("$rex" client ls --json | ${jq} -r 'first(.clients[] | select(.info.kind == "app") | .client_id) // empty')
          if [ -n "$client" ]; then "$rex" -C "$client" do session.select session_id="$session" || true; fi
        '';
      in
      {
        home.file.".linear/coding-tools.json".text = builtins.toJSON {
          openIssue = {
            path = "${openIssue}";
            env = [
              "LINEAR_PROMPT"
              "LINEAR_ISSUE_IDENTIFIER"
              "LINEAR_WORK_DIR"
            ];
          };
        };
      };
  };
}
