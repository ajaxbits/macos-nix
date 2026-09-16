#!/usr/bin/env bash
set -euo pipefail

readonly SCRIPT=${1:?usage: test.sh /path/to/opencode-upside-skills.sh}
readonly TEST_ROOT="$PWD/opencode-upside-test"
readonly STATE="$TEST_ROOT/state"
readonly HOME_DIR="$TEST_ROOT/home"
readonly CACHE="$TEST_ROOT/plugin cache"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

assert_log() {
  grep -Fqx -- "$1" "$STATE/calls" || fail "missing call: $1"
}

mkdir -p "$STATE" "$HOME_DIR" "$CACHE/alpha/current/skills" "$CACHE/hooks/current" "$CACHE/beta current/skills"
cat >"$CACHE/alpha/current/skills/SKILL.md" <<'EOF'
# Alpha
EOF
cat >"$CACHE/beta current/skills/SKILL.md" <<'EOF'
# Beta
EOF
printf '[]\n' >"$STATE/marketplaces.json"
cat >"$STATE/installed.json" <<JSON
[{"id":"alpha@upside-official","scope":"managed","installPath":"$CACHE/alpha/current"}]
JSON
: >"$STATE/calls"

cat >"$TEST_ROOT/claude" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

printf '%s\n' "$*" >>"$CLAUDE_STUB_STATE/calls"

case "$*" in
  'plugin marketplace list --json')
    cat "$CLAUDE_STUB_STATE/marketplaces.json"
    ;;
  'plugin marketplace add upside-services/ai-marketplace --scope user')
    cat >"$CLAUDE_STUB_STATE/marketplaces.json" <<'JSON'
[{"name":"upside-official","source":"github","repo":"upside-services/ai-marketplace"}]
JSON
    ;;
  'plugin marketplace update upside-official')
    ;;
  'plugin list --json')
    cat "$CLAUDE_STUB_STATE/installed.json"
    ;;
  plugin\ install\ *@upside-official\ --scope\ user)
    plugin=${3%@upside-official}
    case "$plugin" in
      alpha) path="$CLAUDE_STUB_CACHE/alpha/current" ;;
      hooks) path="$CLAUDE_STUB_CACHE/hooks/current" ;;
      beta) path="$CLAUDE_STUB_CACHE/beta current" ;;
      *) exit 2 ;;
    esac
    jq --arg id "$plugin@upside-official" --arg path "$path" \
      '. + [{id: $id, scope: "user", enabled: true, installPath: $path}]' \
      "$CLAUDE_STUB_STATE/installed.json" >"$CLAUDE_STUB_STATE/installed.next"
    mv "$CLAUDE_STUB_STATE/installed.next" "$CLAUDE_STUB_STATE/installed.json"
    ;;
  plugin\ update\ *@upside-official\ --scope\ user)
    ;;
  *)
    printf 'unexpected claude call: %s\n' "$*" >&2
    exit 2
    ;;
esac
EOF
chmod +x "$TEST_ROOT/claude"

export HOME="$HOME_DIR"
export UPSIDE_MARKETPLACE=upside-official
export UPSIDE_MARKETPLACE_SOURCE=upside-services/ai-marketplace
export UPSIDE_PLUGINS_JSON='["alpha","hooks","beta"]'
export CLAUDE_PLUGIN_CLI="$TEST_ROOT/claude"
export CLAUDE_STUB_STATE="$STATE"
export CLAUDE_STUB_CACHE="$CACHE"
export UPSIDE_COMMAND_TIMEOUT_SECONDS=10
export OPENCODE_UPSIDE_SKILLS_ROOT="$HOME/.config/opencode/skills/upside"
export OPENCODE_UPSIDE_LOCK_DIR="$HOME/.cache/opencode/upside-refresh.lock"

# A fresh refresh registers the marketplace, installs every declaration, and
# publishes only plugins that contain skills.
bash "$SCRIPT" refresh
assert_log 'plugin marketplace add upside-services/ai-marketplace --scope user'
assert_log 'plugin marketplace update upside-official'
assert_log 'plugin install alpha@upside-official --scope user'
assert_log 'plugin install hooks@upside-official --scope user'
assert_log 'plugin install beta@upside-official --scope user'
[[ "$(readlink "$OPENCODE_UPSIDE_SKILLS_ROOT/alpha")" == "$CACHE/alpha/current/skills" ]]
[[ "$(readlink "$OPENCODE_UPSIDE_SKILLS_ROOT/beta")" == "$CACHE/beta current/skills" ]]
[[ ! -e "$OPENCODE_UPSIDE_SKILLS_ROOT/hooks" ]]

# Repeating maintenance updates user installations instead of reinstalling them.
: >"$STATE/calls"
bash "$SCRIPT" update
assert_log 'plugin update alpha@upside-official --scope user'
assert_log 'plugin update hooks@upside-official --scope user'
assert_log 'plugin update beta@upside-official --scope user'
if grep -Fq 'plugin install' "$STATE/calls"; then
  fail 'repeat update reinstalled a plugin'
fi

# A conflicting marketplace fails before refresh or publication.
cat >"$STATE/marketplaces.json" <<'JSON'
[{"name":"upside-official","source":"github","repo":"someone/else"}]
JSON
: >"$STATE/calls"
if bash "$SCRIPT" refresh; then
  fail 'conflicting marketplace unexpectedly succeeded'
fi
assert_log 'plugin marketplace list --json'
if grep -Fq 'plugin marketplace update' "$STATE/calls"; then
  fail 'conflicting marketplace was updated'
fi
[[ -L "$OPENCODE_UPSIDE_SKILLS_ROOT/alpha" ]]

# Invalid inventory leaves the previously published directory untouched.
cat >"$STATE/installed.json" <<'JSON'
{"not":"an array"}
JSON
touch "$OPENCODE_UPSIDE_SKILLS_ROOT/sentinel"
if bash "$SCRIPT" sync; then
  fail 'malformed inventory unexpectedly succeeded'
fi
[[ -e "$OPENCODE_UPSIDE_SKILLS_ROOT/sentinel" ]]

# Removing a declaration removes only its generated link. Unrelated global
# skills and Claude installations are preserved.
cat >"$STATE/installed.json" <<JSON
[
  {"id":"alpha@upside-official","scope":"user","installPath":"$CACHE/alpha/current"},
  {"id":"beta@upside-official","scope":"user","installPath":"$CACHE/beta current"}
]
JSON
mkdir -p "$HOME/.config/opencode/skills/manual"
touch "$HOME/.config/opencode/skills/manual/SKILL.md"
export UPSIDE_PLUGINS_JSON='["alpha"]'
bash "$SCRIPT" sync
[[ -L "$OPENCODE_UPSIDE_SKILLS_ROOT/alpha" ]]
[[ ! -e "$OPENCODE_UPSIDE_SKILLS_ROOT/beta" ]]
[[ -e "$HOME/.config/opencode/skills/manual/SKILL.md" ]]
jq -e 'any(.[]; .id == "beta@upside-official")' "$STATE/installed.json" >/dev/null

# A live lock blocks overlapping work and does not disturb published links.
mkdir -p "$OPENCODE_UPSIDE_LOCK_DIR"
printf '%s\n' "$$" >"$OPENCODE_UPSIDE_LOCK_DIR/pid"
if bash "$SCRIPT" sync; then
  fail 'overlapping sync unexpectedly succeeded'
fi
[[ -L "$OPENCODE_UPSIDE_SKILLS_ROOT/alpha" ]]
rm -f "$OPENCODE_UPSIDE_LOCK_DIR/pid"
rmdir "$OPENCODE_UPSIDE_LOCK_DIR"

# An empty declaration publishes an empty generated directory without touching
# the marketplace or unrelated skills.
export UPSIDE_PLUGINS_JSON='[]'
: >"$STATE/calls"
bash "$SCRIPT" refresh
[[ -d "$OPENCODE_UPSIDE_SKILLS_ROOT" ]]
[[ -z "$(find "$OPENCODE_UPSIDE_SKILLS_ROOT" -mindepth 1 -maxdepth 1 -print -quit)" ]]
[[ -e "$HOME/.config/opencode/skills/manual/SKILL.md" ]]
[[ ! -s "$STATE/calls" ]]

printf 'opencode upside skills tests passed\n'
