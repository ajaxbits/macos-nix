# Linear desktop app. "Work on issue → Custom script" opens omp on the issue in a new Rex session.
# A prompt that links a GitHub PR gets its own jj workspace, ~/code/<repo>-pr-<n>, on the PR branch;
# the repo is cloned to ~/code/<repo> when missing. Anything else starts in ~/code.
# https://linear.app/docs/open-issues-with-custom-scripts
{
  flake.aspects.linear-work = {
    darwin.homebrew.casks = [ "linear" ];

    homeManager =
      { pkgs, ... }:
      let
        jq = "${pkgs.jq}/bin/jq";
        # Runs inside the Rex session, so jj and gh get fish's PATH and SSH can prompt for Touch ID.
        workOn = pkgs.writeShellScript "linear-work-on" ''
          set -u
          prompt=''${1:-}
          run_omp() {
            cd "$1"
            if [ -n "$prompt" ]; then exec omp "$prompt"; fi
            exec omp
          }
          fail() {
            printf 'linear: %s\nPress Enter to start omp in ~/code instead.\n' "$1" >&2
            read -r _
            run_omp "$HOME/code"
          }
          url=$(printf '%s\n' "$prompt" | grep -oE 'https://github\.com/[^/ ]+/[^/ ]+/pull/[0-9]+' | head -n1)
          [ -n "$url" ] || run_omp "$HOME/code"
          IFS=/ read -r _ _ _ owner name _ number <<<"$url"
          repo="$HOME/code/$name"
          ws="$repo-pr-$number"
          # Reopening the same PR reuses its workspace as is.
          [ -d "$ws/.jj" ] && run_omp "$ws"
          [ -d "$repo" ] || jj git clone --colocate "git@github.com:$owner/$name.git" "$repo" || fail "could not clone $owner/$name"
          [ -d "$repo/.jj" ] || (cd "$repo" && jj git init --colocate) || fail "could not colocate jj in $repo"
          branch=$(printf '%s\n' "$prompt" | sed -n 's/^Checkout branch: `\(.*\)`$/\1/p' | head -n1)
          [ -n "$branch" ] || branch=$(gh pr view "$number" -R "$owner/$name" --json headRefName -q .headRefName) || fail "could not find the branch of PR #$number"
          # Snapshotting the main checkout only records its edits in jj; it never rewrites files there.
          jj -R "$repo" git fetch --branch "$branch" || fail "could not fetch $branch"
          jj -R "$repo" bookmark track --remote origin "exact:$branch" || fail "could not track $branch@origin"
          # A workspace whose directory was deleted is still registered in jj and git; drop it so the name is free.
          jj -R "$repo" workspace forget "pr-$number" 2>/dev/null
          git -C "$repo" worktree prune
          jj -R "$repo" workspace add --name "pr-$number" -r "\"$branch\"@origin" "$ws" || fail "could not create workspace $ws"
          run_omp "$ws"
        '';
        openIssue = pkgs.writeShellScript "linear-open-issue" ''
          set -eu
          # Linear runs this from the GUI with a bare PATH, so call rex by its stable install path.
          rex="$HOME/Library/Application Support/com.superlogical.rex/RexServer/Versions/Current/Rex Server.app/Contents/MacOS/rex"
          label=$(printf '%s' "''${LINEAR_ISSUE_IDENTIFIER:-linear-issue}" | tr '[:upper:]' '[:lower:]')
          # --interactive loads fish's interactive config, so omp gets the usual PATH and secrets.
          session=$("$rex" new "$label" -c "$HOME/code" --interactive --json -- ${workOn} "''${LINEAR_PROMPT:-}" | ${jq} -r .session_id)
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
            ];
          };
        };
      };
  };
}
