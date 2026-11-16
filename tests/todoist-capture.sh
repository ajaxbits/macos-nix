#!/usr/bin/env bash
set -euo pipefail

readonly SCRIPT=${1:?usage: test.sh /path/to/todoist-capture.sh}
readonly TEST_ROOT="$PWD/todoist-capture-test"
export TODOIST_CAPTURE_STATE="$TEST_ROOT/state"
export TODOIST_CAPTURE_CONFIG="$TEST_ROOT/omp.yml"
export OMP="$TEST_ROOT/omp"
export OSASCRIPT="$TEST_ROOT/osascript"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

count() {
  find "$TODOIST_CAPTURE_STATE/$1" -mindepth 1 | wc -l | tr -d ' '
}

mkdir -p "$TEST_ROOT"
: >"$TODOIST_CAPTURE_CONFIG"
cat >"$OMP" <<'EOF'
#!/usr/bin/env bash
echo call >>"$(dirname "$0")/omp-calls"
case "${!#}" in
  *good*) echo "ADDED: Buy milk" ;;
  *)
    echo "FAILED: nope"
    exit 1
    ;;
esac
EOF
cat >"$OSASCRIPT" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$(dirname "$0")/notifications"
EOF
chmod +x "$OMP" "$OSASCRIPT"

"$SCRIPT" add good note here >/dev/null
printf 'bad note\n' | "$SCRIPT" add >/dev/null
if printf '  \n' | "$SCRIPT" add 2>/dev/null; then
  fail "blank note was queued"
fi
[[ $(count inbox) == 2 ]] || fail "expected 2 queued notes, got $(count inbox)"
grep -Fqx 'good note here' "$TODOIST_CAPTURE_STATE"/inbox/* || fail "argument note not queued verbatim"
[[ $(count tmp) == 0 ]] || fail "temp note left behind"
: >"$TODOIST_CAPTURE_STATE/inbox/.DS_Store"

"$SCRIPT" drain >/dev/null

[[ $(count inbox) == 0 ]] || fail "inbox not emptied; launchd would relaunch forever"
[[ $(count "done") == 1 ]] || fail "expected 1 done note, got $(count "done")"
[[ $(count failed) == 2 ]] || fail "expected the failed note and the stray file in failed/, got $(count failed)"
[[ $(wc -l <"$TEST_ROOT/omp-calls" | tr -d ' ') == 2 ]] || fail "omp must run once per real note and never for dotfiles"
grep -Fq 'Buy milk' "$TEST_ROOT/notifications" || fail "success notification lacks the task title"
grep -Fq 'Todoist capture failed' "$TEST_ROOT/notifications" || fail "failure notification missing"
