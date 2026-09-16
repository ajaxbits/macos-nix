#!/usr/bin/env bash
# jq variables such as $id and $name are intentionally single-quoted below.
# shellcheck disable=SC2016
set -euo pipefail

readonly MARKETPLACE="${UPSIDE_MARKETPLACE:-upside-official}"
readonly MARKETPLACE_SOURCE="${UPSIDE_MARKETPLACE_SOURCE:-upside-services/ai-marketplace}"
readonly PLUGINS_JSON="${UPSIDE_PLUGINS_JSON:-[]}"
readonly CLAUDE_PLUGIN_CLI="${CLAUDE_PLUGIN_CLI:-claude}"
readonly JQ="${JQ:-jq}"
readonly TIMEOUT="${TIMEOUT:-timeout}"
readonly COMMAND_TIMEOUT_SECONDS="${UPSIDE_COMMAND_TIMEOUT_SECONDS:-180}"
readonly SKILLS_ROOT="${OPENCODE_UPSIDE_SKILLS_ROOT:-${HOME}/.config/opencode/skills/upside}"
readonly LOCK_DIR="${OPENCODE_UPSIDE_LOCK_DIR:-${HOME}/.cache/opencode/upside-refresh.lock}"

lock_owned=0
work_dir=""
stage_dir=""
backup_dir=""

log() {
  printf '[upside-skills] %s\n' "$*"
}

cleanup() {
  local status=$?

  if [[ -n "$stage_dir" && -d "$stage_dir" ]]; then
    rm -rf -- "$stage_dir"
  fi
  if [[ -n "$backup_dir" && -d "$backup_dir" ]]; then
    if [[ ! -e "$SKILLS_ROOT" && ! -L "$SKILLS_ROOT" ]]; then
      mv "$backup_dir" "$SKILLS_ROOT" || log "could not restore previous skills directory"
    else
      rm -rf -- "$backup_dir"
    fi
  fi
  if [[ -n "$work_dir" && -d "$work_dir" ]]; then
    rm -rf -- "$work_dir"
  fi
  if [[ "$lock_owned" == 1 ]]; then
    rm -f -- "$LOCK_DIR/pid"
    rmdir "$LOCK_DIR" 2>/dev/null || true
  fi

  return "$status"
}

trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM HUP

validate_configuration() {
  "$JQ" -e '
    type == "array"
    and all(.[]; type == "string" and test("^[a-z0-9]+(-[a-z0-9]+)*$"))
    and (length == (unique | length))
  ' <<<"$PLUGINS_JSON" >/dev/null
}

acquire_lock() {
  local holder=""

  mkdir -p -- "${LOCK_DIR%/*}"
  if ! mkdir "$LOCK_DIR" 2>/dev/null; then
    if [[ -r "$LOCK_DIR/pid" ]]; then
      holder="$(cat "$LOCK_DIR/pid")"
    fi

    if [[ "$holder" =~ ^[0-9]+$ ]] && kill -0 "$holder" 2>/dev/null; then
      log "another refresh is running (pid $holder)"
      return 75
    fi

    rm -f -- "$LOCK_DIR/pid"
    if ! rmdir "$LOCK_DIR" 2>/dev/null || ! mkdir "$LOCK_DIR" 2>/dev/null; then
      log "could not recover stale lock: $LOCK_DIR"
      return 75
    fi
  fi

  printf '%s\n' "$$" >"$LOCK_DIR/pid"
  lock_owned=1
}

make_work_dir() {
  if [[ -z "$work_dir" ]]; then
    work_dir="$(mktemp -d "${TMPDIR:-/tmp}/opencode-upside.XXXXXX")"
  fi
}

run_claude() {
  "$TIMEOUT" "$COMMAND_TIMEOUT_SECONDS" "$CLAUDE_PLUGIN_CLI" "$@"
}

read_marketplaces() {
  local output=$1

  run_claude plugin marketplace list --json >"$output"
  "$JQ" -e '
    type == "array"
    and all(.[]; type == "object" and (.name | type == "string"))
  ' "$output" >/dev/null
}

read_installed_plugins() {
  local output=$1

  run_claude plugin list --json >"$output"
  "$JQ" -e '
    type == "array"
    and all(.[];
      type == "object"
      and (.id | type == "string")
      and (.scope | type == "string")
    )
  ' "$output" >/dev/null
}

update_plugins() {
  local marketplaces installed plugin plugin_id matching_names matching_source

  if [[ "$("$JQ" 'length' <<<"$PLUGINS_JSON")" == 0 ]]; then
    log "no declared plugins to maintain"
    return
  fi

  make_work_dir
  marketplaces="$work_dir/marketplaces.json"
  installed="$work_dir/installed.json"
  read_marketplaces "$marketplaces"

  matching_names="$("$JQ" --arg name "$MARKETPLACE" '[.[] | select(.name == $name)] | length' "$marketplaces")"
  matching_source="$(
    "$JQ" --arg name "$MARKETPLACE" --arg repo "$MARKETPLACE_SOURCE" \
      '[.[] | select(.name == $name and .source == "github" and .repo == $repo)] | length' \
      "$marketplaces"
  )"

  if [[ "$matching_names" == 0 ]]; then
    log "register marketplace $MARKETPLACE from $MARKETPLACE_SOURCE"
    run_claude plugin marketplace add "$MARKETPLACE_SOURCE" --scope user
  elif [[ "$matching_names" != 1 || "$matching_source" != 1 ]]; then
    log "marketplace $MARKETPLACE is registered from an unexpected source"
    return 1
  fi

  log "refresh marketplace $MARKETPLACE"
  run_claude plugin marketplace update "$MARKETPLACE"
  read_installed_plugins "$installed"

  while IFS= read -r plugin; do
    plugin_id="${plugin}@${MARKETPLACE}"
    if "$JQ" -e --arg id "$plugin_id" \
      'any(.[]; .id == $id and .scope == "user")' "$installed" >/dev/null; then
      log "update $plugin_id"
      run_claude plugin update "$plugin_id" --scope user
    else
      log "install $plugin_id"
      run_claude plugin install "$plugin_id" --scope user
    fi
  done < <("$JQ" -r '.[]' <<<"$PLUGINS_JSON")
}

sync_skills() {
  local installed parent plugin plugin_id path matches linked=0

  make_work_dir
  installed="$work_dir/installed-for-sync.json"
  parent="${SKILLS_ROOT%/*}"
  mkdir -p -- "$parent"
  stage_dir="$(mktemp -d "$parent/.upside-sync.XXXXXX")"

  if [[ "$("$JQ" 'length' <<<"$PLUGINS_JSON")" != 0 ]]; then
    read_installed_plugins "$installed"
  fi

  while IFS= read -r plugin; do
    plugin_id="${plugin}@${MARKETPLACE}"
    matches="$(
      "$JQ" --arg id "$plugin_id" \
        '[.[] | select(.id == $id and .scope == "user" and (.installPath | type == "string"))] | length' \
        "$installed"
    )"
    if [[ "$matches" != 1 ]]; then
      log "expected one user installation for $plugin_id, found $matches"
      return 1
    fi

    path="$(
      "$JQ" -r --arg id "$plugin_id" \
        '.[] | select(.id == $id and .scope == "user") | .installPath' "$installed"
    )"
    if [[ ! -d "$path" ]]; then
      log "installation path is unavailable for $plugin_id: $path"
      return 1
    fi
    if [[ ! -d "$path/skills" ]]; then
      log "skip $plugin_id (no skills/)"
      continue
    fi

    ln -s -- "$path/skills" "$stage_dir/$plugin"
    log "link $plugin -> $path/skills"
    linked=$((linked + 1))
  done < <("$JQ" -r '.[]' <<<"$PLUGINS_JSON")

  if [[ -e "$SKILLS_ROOT" || -L "$SKILLS_ROOT" ]]; then
    backup_dir="$(mktemp -d "$parent/.upside-old.XXXXXX")"
    rmdir "$backup_dir"
    mv "$SKILLS_ROOT" "$backup_dir"
  fi

  if ! mv "$stage_dir" "$SKILLS_ROOT"; then
    if [[ -n "$backup_dir" && -d "$backup_dir" ]]; then
      mv "$backup_dir" "$SKILLS_ROOT"
      backup_dir=""
    fi
    return 1
  fi
  stage_dir=""

  if [[ -n "$backup_dir" && -d "$backup_dir" ]]; then
    rm -rf -- "$backup_dir"
    backup_dir=""
  fi
  log "published $linked plugin skill director$( [[ "$linked" == 1 ]] && printf 'y' || printf 'ies' ) at $SKILLS_ROOT"
}

usage() {
  printf 'usage: %s {update|sync|refresh}\n' "${0##*/}" >&2
  exit 64
}

validate_configuration
acquire_lock

case "${1:-}" in
  update)
    update_plugins
    ;;
  sync)
    sync_skills
    ;;
  refresh)
    update_plugins
    sync_skills
    ;;
  *)
    usage
    ;;
esac
