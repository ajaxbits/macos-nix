#!/bin/bash
set -euo pipefail
umask 077

HOSTS_FILE=${BOOTSTRAP_HOSTS_FILE:?BOOTSTRAP_HOSTS_FILE is required}
SOURCE_REV=${BOOTSTRAP_SOURCE_REV:?BOOTSTRAP_SOURCE_REV is required}
REPO_URL=${BOOTSTRAP_REPO_URL:?BOOTSTRAP_REPO_URL is required}
NIX=${NIX:?NIX is required}
GIT=${GIT:?GIT is required}
AGENIX=${AGENIX:?AGENIX is required}
AGE_PLUGIN_SE=${AGE_PLUGIN_SE:?AGE_PLUGIN_SE is required}
AGENIX_SE_KEYGEN=${AGENIX_SE_KEYGEN:?AGENIX_SE_KEYGEN is required}
DARWIN_REBUILD=${DARWIN_REBUILD:?DARWIN_REBUILD is required}
HOMEBREW_INSTALLER=${HOMEBREW_INSTALLER:?HOMEBREW_INSTALLER is required}

ID=${ID:-/usr/bin/id}
UNAME=${UNAME:-/usr/bin/uname}
SCUTIL=${SCUTIL:-/usr/sbin/scutil}
XCODE_SELECT=${XCODE_SELECT:-/usr/bin/xcode-select}
SUDO=${SUDO:-/usr/bin/sudo}
BREW=${BREW:-/opt/homebrew/bin/brew}
SYSTEM_NIX=${SYSTEM_NIX:-/run/current-system/sw/bin/nix}
SYSTEM_DARWIN_REBUILD=${SYSTEM_DARWIN_REBUILD:-/run/current-system/sw/bin/darwin-rebuild}
SYSTEM_PROFILE=${SYSTEM_PROFILE:-/nix/var/nix/profiles/system}
STAT=${STAT:-/usr/bin/stat}
DSCL=${DSCL:-/usr/bin/dscl}
INTEL_BREW=${INTEL_BREW:-/usr/local/bin/brew}

usage() {
  cat <<'EOF'
Usage:
  macos-nix-bootstrap --check --host NAME [--checkout PATH]
  macos-nix-bootstrap --prepare-enrollment --host NAME [--profile work]
  macos-nix-bootstrap --apply --host NAME [--checkout PATH] [--allow-existing-darwin]

Modes:
  --check               Read-only readiness report. Does not use sudo or create keys.
  --prepare-enrollment  Create or inspect this Mac's Secure Enclave identity, then
                        print the public-recipient enrollment instructions.
  --apply               Verify enrollment and prerequisites, build the reviewed
                        configuration, ask for confirmation, and perform first switch.

Run from a full reviewed revision, for example:
  nix run github:ajaxbits/macos-nix/REV#bootstrap -- --check --host NAME

The script is resumable. It never overwrites an identity, changes a dirty checkout,
or silently substitutes another host/profile.
EOF
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

step() {
  printf '\n==> %s\n' "$*"
}

ok() {
  printf '  [ok] %s\n' "$*"
}

note() {
  printf '  [note] %s\n' "$*"
}

confirm() {
  printf '%s Type yes to continue: ' "$1"
  read -r answer
  test "$answer" = yes || die "cancelled"
}

mode=
host_name=
requested_profile=
checkout=
allow_existing_darwin=0
while test "$#" -gt 0; do
  case "$1" in
    --check|--prepare-enrollment|--apply)
      test -z "$mode" || die "choose exactly one mode"
      mode=$1
      shift
      ;;
    --host)
      test "$#" -ge 2 || die "--host requires a value"
      host_name=$2
      shift 2
      ;;
    --profile)
      test "$#" -ge 2 || die "--profile requires a value"
      requested_profile=$2
      shift 2
      ;;
    --checkout)
      test "$#" -ge 2 || die "--checkout requires a value"
      checkout=$2
      shift 2
      ;;
    --allow-existing-darwin)
      allow_existing_darwin=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *) die "unknown argument: $1" ;;
  esac
done

test -n "$mode" || { usage >&2; exit 2; }
test -n "$host_name" || die "--host is required"
jq -e --arg host "$host_name" 'has($host)' "$HOSTS_FILE" >/dev/null || die "unknown host output: $host_name"

host_json=$(jq -c --arg host "$host_name" '.[$host]' "$HOSTS_FILE")
host_value() {
  jq -r "$1" <<<"$host_json"
}

profile=$(host_value '.profile')
user_name=$(host_value '.userName')
home_directory=$(host_value '.homeDirectory')
uid=$(host_value '.uid')
machine_hostname=$(host_value '.hostName')
system=$(host_value '.system')
identity_path=$(host_value '.ageIdentityPath')
identity_type=$(host_value '.ageIdentityType')

if test -n "$requested_profile" && test "$requested_profile" != "$profile"; then
  die "host $host_name selects profile $profile, not $requested_profile"
fi
if test -z "$checkout"; then
  checkout=$(host_value '.flakeDirectory')
fi
case "$checkout" in /*) ;; *) die "checkout path must be absolute" ;; esac

state_dir="$home_directory/Library/Application Support/macos-nix-bootstrap"
state_file="$state_dir/state.json"
lock_dir="$state_dir/run.lock"
secret_scratch=
lock_active=0

cleanup_runtime() {
  status=$?
  if test -n "$secret_scratch"; then
    rm -rf -- "$secret_scratch"
  fi
  if test "$lock_active" = 1; then
    rm -rf -- "$lock_dir"
  fi
  exit "$status"
}
trap cleanup_runtime EXIT INT TERM

require_immutable_revision() {
  [[ "$SOURCE_REV" =~ ^[0-9a-f]{40}$ ]] || die "this operation must run from a full immutable Git revision, got: $SOURCE_REV"
}

validate_homebrew() {
  test -x "$BREW" || return 1
  test "$("$BREW" --prefix)" = /opt/homebrew || die "Homebrew at $BREW reports an unexpected prefix"
  "$BREW" --version >/dev/null || die "Homebrew at $BREW is not healthy"
}

preflight() {
  step "Checking machine and selected host"
  test "$($ID -u)" != 0 || die "run bootstrap as the logged-in user, not root"
  test "$($UNAME -s)" = Darwin || die "bootstrap supports macOS only"
  test "$($UNAME -m)" = arm64 || die "bootstrap must run natively on Apple Silicon"
  test "$system" = aarch64-darwin || die "selected host is not an Apple Silicon Darwin host"
  test "$($ID -un)" = "$user_name" || die "current user does not match host record ($user_name)"
  test "$($ID -u)" = "$uid" || die "current UID does not match host record ($uid)"
  test "$HOME" = "$home_directory" || die "HOME does not match host record ($home_directory)"
  test "$($STAT -f '%Su' /dev/console)" = "$user_name" || die "selected user is not the active macOS console user"
  account_home=$($DSCL . -read "/Users/$user_name" NFSHomeDirectory | sed -n 's/^NFSHomeDirectory: //p')
  test "$account_home" = "$home_directory" || die "directory-service home does not match host record ($home_directory)"
  test "$($SCUTIL --get LocalHostName)" = "$machine_hostname" || die "LocalHostName does not match host record ($machine_hostname)"
  "$NIX" --version | grep -q Lix || die "the active Nix command is not Lix"
  ok "host $host_name selects $profile for $user_name"
  ok "Lix is available"

  if "$XCODE_SELECT" -p >/dev/null 2>&1; then
    ok "Apple Command Line Tools are available"
  else
    note "Apple Command Line Tools are not installed"
  fi
  if validate_homebrew; then
    ok "Homebrew is available at $BREW"
  elif test -x "$INTEL_BREW"; then
    die "found an alternate Homebrew at $INTEL_BREW; review it before installing native Homebrew"
  else
    note "Homebrew is not installed at $BREW"
  fi
  if test -e "$identity_path"; then
    ok "age identity exists at the configured path"
  else
    note "age identity is not yet present"
  fi
  if test -x "$SYSTEM_DARWIN_REBUILD"; then
    note "nix-darwin is already installed; review whether this is a migration"
    if test "$mode" = --apply && test "$allow_existing_darwin" != 1; then
      die "refusing first-switch mode on an existing nix-darwin system; rerun with --allow-existing-darwin after review"
    fi
  fi
  note "this flake requests its declared binary caches/trusted keys; review the Nix trust prompt before accepting"
}

write_state() {
  phase=$1
  recipient=${2:-}
  mkdir -p "$state_dir"
  chmod 0700 "$state_dir"
  jq -n \
    --arg host "$host_name" \
    --arg revision "$SOURCE_REV" \
    --arg phase "$phase" \
    --arg identity "$identity_path" \
    --arg recipient "$recipient" \
    --arg checkout "$checkout" \
    --arg updatedAt "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{host:$host,revision:$revision,phase:$phase,identityPath:$identity,publicRecipient:$recipient,checkout:$checkout,updatedAt:$updatedAt}' \
    > "$state_file.tmp"
  chmod 0600 "$state_file.tmp"
  mv "$state_file.tmp" "$state_file"
}

public_recipient() {
  "$AGE_PLUGIN_SE" recipients -i "$identity_path" | sed -n '/^age1se1/p' | head -n 1
}

validate_identity() {
  test -f "$identity_path" || die "identity is not a regular file: $identity_path"
  test ! -L "$identity_path" || die "identity must not be a symlink: $identity_path"
  test "$($STAT -f '%u' "$identity_path")" = "$uid" || die "identity is not owned by the configured user"
  identity_mode=$($STAT -f '%Lp' "$identity_path")
  test $((8#$identity_mode & 077)) -eq 0 || die "identity must not grant group/other access"
  identity_parent=$(dirname "$identity_path")
  test "$($STAT -f '%u' "$identity_parent")" = "$uid" || die "identity parent is not user-owned"
  parent_mode=$($STAT -f '%Lp' "$identity_parent")
  test $((8#$parent_mode & 077)) -eq 0 || die "identity parent must not grant group/other access"
}

print_enrollment() {
  recipient=$1
  cat <<EOF

Enrollment is the next required step.

Public recipient (safe to transfer):
  $recipient

On an already authorized device or with the recovery custodian:
  1. Add this recipient to Kagi and each intended work-secret rule.
  2. Rekey those .age files with the authorized identity.
  3. Add/review the real host record and encrypted files.
  4. Commit and publish that revision.

Then rerun bootstrap from that exact new revision. Do not copy this Mac's private
identity or a recovery private key to another device.
EOF
}

prepare_enrollment() {
  require_immutable_revision
  test "$identity_type" = secure-enclave || die "host uses $identity_type identity; Secure Enclave generation is not applicable"
  step "Preparing unattended Secure Enclave identity"
  if test -e "$identity_path"; then
    validate_identity
    recipient=$(public_recipient)
    test -n "$recipient" || die "existing identity did not produce a Secure Enclave recipient"
    ok "reusing the existing device-bound identity"
  else
    confirm "Create a device-bound identity at $identity_path?"
    "$AGENIX_SE_KEYGEN" "$identity_path"
    recipient=$(public_recipient)
    test -n "$recipient" || die "new identity did not produce a Secure Enclave recipient"
    ok "created the identity without biometric/passcode access control"
  fi
  write_state waiting-for-enrollment "$recipient"
  print_enrollment "$recipient"
}

acquire_lock() {
  mkdir -p "$state_dir"
  chmod 0700 "$state_dir"
  if ! mkdir "$lock_dir" 2>/dev/null; then
    existing_pid=$(jq -r '.pid // empty' "$lock_dir/run.json" 2>/dev/null || true)
    if test -n "$existing_pid" && kill -0 "$existing_pid" 2>/dev/null; then
      die "another bootstrap run is active with PID $existing_pid"
    fi
    confirm "The bootstrap lock is stale. Remove $lock_dir?"
    rm -rf -- "$lock_dir"
    mkdir "$lock_dir" || die "could not acquire bootstrap lock"
  fi
  lock_active=1
  jq -n --arg host "$host_name" --arg revision "$SOURCE_REV" --arg pid "$$" \
    --arg startedAt "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{host:$host,revision:$revision,pid:$pid,startedAt:$startedAt}' > "$lock_dir/run.json"
}

ensure_checkout() {
  step "Preparing reviewed source checkout"
  require_immutable_revision
  if test ! -e "$checkout"; then
    confirm "Clone $REPO_URL at $SOURCE_REV into $checkout?"
    mkdir -p "$(dirname "$checkout")"
    "$GIT" clone --no-checkout "$REPO_URL" "$checkout"
    "$GIT" -C "$checkout" checkout --detach "$SOURCE_REV"
  else
    test -d "$checkout/.git" || die "existing checkout is not a Git checkout: $checkout"
    test -z "$("$GIT" -C "$checkout" status --porcelain)" || die "existing checkout is dirty; preserve it and choose another path"
    test "$("$GIT" -C "$checkout" rev-parse HEAD)" = "$SOURCE_REV" || die "checkout revision differs from bootstrap revision"
  fi
  ok "checkout matches $SOURCE_REV"
}

check_secret_readiness() {
  step "Checking encrypted secret enrollment"
  test -r "$identity_path" || die "identity is missing: run --prepare-enrollment first"
  validate_identity
  secret_scratch=$(mktemp -d "${TMPDIR:-/tmp}/macos-nix-secret-check.XXXXXX")
  chmod 0700 "$secret_scratch"
  secret_failure=0
  while IFS= read -r secret_file; do
    if ! (
      cd "$checkout/secrets"
      RULES=./secrets.nix "$AGENIX" -d "$secret_file" -i "$identity_path" > "$secret_scratch/plaintext"
    ); then
      secret_failure=1
      break
    fi
    rm -f "$secret_scratch/plaintext"
    ok "$secret_file is decryptable by this device"
  done < <(jq -r '.secretFiles[]' <<<"$host_json")
  rm -rf "$secret_scratch"
  secret_scratch=
  test "$secret_failure" = 0 || die "recipient enrollment is incomplete; rekey on an authorized device and resume from its revision"
}

ensure_clt() {
  if "$XCODE_SELECT" -p >/dev/null 2>&1; then
    return
  fi
  step "Installing Apple Command Line Tools"
  confirm "Open Apple's Command Line Tools installer?"
  "$XCODE_SELECT" --install
  write_state waiting-for-command-line-tools
  note "finish the Apple installer, then rerun --apply"
  exit 5
}

ensure_homebrew() {
  if validate_homebrew; then
    return
  fi
  test ! -x "$INTEL_BREW" || die "alternate Homebrew exists at $INTEL_BREW; refusing a second installation"
  step "Installing Homebrew"
  confirm "Run the repository-pinned official Homebrew installer?"
  "$SUDO" -v
  env -i HOME="$HOME" USER="$user_name" NONINTERACTIVE=1 PATH=/usr/bin:/bin:/usr/sbin:/sbin \
    /bin/bash "$HOMEBREW_INSTALLER"
  validate_homebrew || die "Homebrew installer finished but $BREW is unavailable"
  ok "Homebrew installed"
}

build_and_switch() {
  step "Checking and building the reviewed system"
  source_ref="github:ajaxbits/macos-nix/$SOURCE_REV"
  "$NIX" flake check --no-write-lock-file "$source_ref"
  result_link="$state_dir/system-result"
  "$NIX" build --no-write-lock-file --out-link "$result_link" \
    "$source_ref#darwinConfigurations.$host_name.system"
  built_system=$(realpath "$result_link")
  write_state ready-to-switch

  test -z "$("$GIT" -C "$checkout" status --porcelain)" || die "checkout changed after review; refusing activation"
  test "$("$GIT" -C "$checkout" rev-parse HEAD)" = "$SOURCE_REV" || die "checkout revision changed after review"

  step "Checking activation and Home Manager collisions"
  confirm "Run the pinned privileged activation check before switching?"
  if ! "$SUDO" "$DARWIN_REBUILD" check --no-write-lock-file --flake "$source_ref#$host_name"; then
    write_state activation-check-failed
    die "activation check failed; review collisions or policy errors before retrying"
  fi
  ok "activation check passed"

  cat <<EOF

Ready for the first switch:
  Host:       $host_name
  Profile:    $profile
  User:       $user_name ($uid)
  Source:     $SOURCE_REV
  Checkout:   $checkout
  System:     $built_system
  Homebrew:   existing or installed without cleanup/upgrade outside configuration

The switch will request your administrator password and activate nix-darwin and
Home Manager. It will not authenticate Tailscale, AWS, Jira, GitHub, or OpenCode.
EOF
  confirm "Activate this exact host configuration?"
  if ! "$SUDO" "$DARWIN_REBUILD" switch --no-write-lock-file --flake "$source_ref#$host_name"; then
    write_state activation-failed
    die "switch failed after activation began; inspect the partial system state before retrying"
  fi
  write_state switch-completed

  step "Verifying the switched system"
  if test ! -x "$SYSTEM_DARWIN_REBUILD"; then
    write_state verification-failed
    die "switch returned success but darwin-rebuild is not installed"
  fi
  if ! "$SYSTEM_NIX" --version | grep -q Lix; then
    write_state verification-failed
    die "switched system is not using Lix"
  fi
  if test ! -e "$SYSTEM_PROFILE"; then
    write_state verification-failed
    die "the nix-darwin system profile does not exist after switching"
  fi
  active_system=$(realpath "$SYSTEM_PROFILE")
  if test "$active_system" != "$built_system"; then
    write_state verification-failed
    die "active system $active_system differs from reviewed build $built_system"
  fi
  write_state verified
  ok "nix-darwin is installed and Lix remains active"
  note "complete app logins, macOS permissions, MDM delivery, and a separately approved fresh-login test"
}

case "$mode" in
  --check)
    preflight
    ;;
  --prepare-enrollment)
    preflight
    acquire_lock
    prepare_enrollment
    ;;
  --apply)
    preflight
    acquire_lock
    if test "$identity_type" = secure-enclave && test ! -e "$identity_path"; then
      prepare_enrollment
      exit 4
    fi
    ensure_checkout
    check_secret_readiness
    ensure_clt
    ensure_homebrew
    build_and_switch
    ;;
esac
