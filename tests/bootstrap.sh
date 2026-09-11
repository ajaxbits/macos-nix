#!/bin/bash
set -euo pipefail

driver=$1
root=$(mktemp -d "${TMPDIR:-/tmp}/macos-nix-bootstrap-test.XXXXXX")
trap 'rm -rf -- "$root"' EXIT
mkdir -p "$root/bin" "$root/home/private" "$root/checkout/.git" "$root/checkout/secrets" "$root/system/bin"
chmod 0700 "$root/home/private"

cat > "$root/hosts.json" <<EOF
{
  "TestWork": {
    "outputName": "TestWork",
    "hostName": "Test-Mac",
    "profile": "work",
    "system": "aarch64-darwin",
    "userName": "test-user",
    "homeDirectory": "$root/home",
    "uid": 777,
    "ageIdentityPath": "$root/home/private/identity.txt",
    "ageIdentityType": "secure-enclave",
    "deploymentReady": true,
    "flakeDirectory": "$root/checkout",
    "secretFiles": ["kagi_api_key.age"]
  }
}
EOF

cat > "$root/bin/id" <<'EOF'
#!/bin/bash
case "$1" in
  -u) echo 777 ;;
  -un) echo test-user ;;
  *) exit 1 ;;
esac
EOF
cat > "$root/bin/uname" <<'EOF'
#!/bin/bash
case "$1" in
  -s) echo Darwin ;;
  -m) echo arm64 ;;
  *) exit 1 ;;
esac
EOF
cat > "$root/bin/scutil" <<'EOF'
#!/bin/bash
test "$1" = --get && test "$2" = LocalHostName
echo Test-Mac
EOF
cat > "$root/bin/stat" <<'EOF'
#!/bin/bash
test "$1" = -f
case "$2" in
  %Su) echo "${CONSOLE_USER:-test-user}" ;;
  %u) echo 777 ;;
  %Lp) /usr/bin/stat -f '%Lp' "$3" ;;
  *) exit 1 ;;
esac
EOF
cat > "$root/bin/dscl" <<EOF
#!/bin/bash
echo 'NFSHomeDirectory: $root/home'
EOF
cat > "$root/bin/xcode-select" <<'EOF'
#!/bin/bash
if test "$1" = -p; then
  test "${CLT_READY:-0}" = 1
elif test "$1" = --install; then
  touch "$TEST_ROOT/clt-install-requested"
else
  exit 1
fi
EOF
cat > "$root/bin/agenix" <<'EOF'
#!/bin/bash
test "${AGENIX_FAIL:-0}" = 0 || exit 12
printf 'dummy secret'
EOF
cat > "$root/bin/age-plugin-se" <<'EOF'
#!/bin/bash
test "$1" = recipients
cat "$3.recipient"
EOF
cat > "$root/bin/keygen" <<'EOF'
#!/bin/bash
set -euo pipefail
mkdir -p "$(dirname "$1")"
printf 'device identity\n' > "$1"
printf 'age1se1bootstraptest\n' > "$1.recipient"
chmod 0600 "$1" "$1.recipient"
EOF
cat > "$root/bin/nix" <<'EOF'
#!/bin/bash
set -euo pipefail
if test "$1" = --version; then
  echo 'nix (Lix, like Nix) test'
  exit 0
fi
printf '%s\n' "$*" >> "$TEST_ROOT/nix.calls"
if test "$1" = flake && test "$2" = archive; then
  printf '{"path":"%s"}\n' "$TEST_ROOT/archived-source"
  exit 0
fi
if test "$1" = flake && test "$2" = check; then
  exit 0
fi
if test "$1" = hash && test "$2" = path; then
  echo sha256-bootstrap-test
  exit 0
fi
if test "$1" = build; then
  test "${NIX_FAIL_BUILD:-0}" = 0 || exit 17
  while test "$#" -gt 0; do
    if test "$1" = --out-link; then
      shift
      ln -sfn "$TEST_ROOT/built-system" "$1"
      exit 0
    fi
    shift
  done
fi
exit 1
EOF
cat > "$root/bin/darwin-rebuild" <<'EOF'
#!/bin/bash
printf '%s\n' "$*" > "$TEST_ROOT/switch.args"
if test "$1" = check && test "${DARWIN_CHECK_FAIL:-0}" = 1; then
  exit 19
fi
if test "$1" = switch && test "${DARWIN_SWITCH_FAIL:-0}" = 1; then
  exit 20
fi
if test "$1" = switch; then
  mkdir -p "$(dirname "$SYSTEM_DARWIN_REBUILD")" "$(dirname "$SYSTEM_PROFILE")"
  cp "$0" "$SYSTEM_DARWIN_REBUILD"
  if test "${PROFILE_MISMATCH:-0}" = 1; then
    mkdir -p "$TEST_ROOT/other-system"
    ln -sfn "$TEST_ROOT/other-system" "$SYSTEM_PROFILE"
  else
    ln -sfn "$TEST_ROOT/built-system" "$SYSTEM_PROFILE"
  fi
fi
EOF
cat > "$root/bin/sudo" <<'EOF'
#!/bin/bash
if test "$1" = -v; then
  exit 0
fi
printf '%s\n' "$*" > "$TEST_ROOT/sudo.args"
"$@"
EOF
cat > "$root/homebrew-installer" <<EOF
#!/bin/bash
test "\$NONINTERACTIVE" = 1
cat > "$root/bin/brew" <<'BREW'
#!/bin/bash
case "\$1" in
  --prefix) echo /opt/homebrew ;;
  --version) echo 'Homebrew test' ;;
  *) exit 0 ;;
esac
BREW
chmod +x "$root/bin/brew"
EOF
chmod +x "$root/bin"/* "$root/homebrew-installer"
mkdir "$root/built-system" "$root/archived-source"
printf 'encrypted fixture\n' > "$root/checkout/secrets/kagi_api_key.age"
printf '{}\n' > "$root/checkout/secrets/secrets.nix"
printf '{}\n' > "$root/checkout/flake.nix"

export HOME="$root/home"
export TEST_ROOT="$root"
export BOOTSTRAP_HOSTS_FILE="$root/hosts.json"
export NIX="$root/bin/nix"
export AGENIX="$root/bin/agenix"
export AGE_PLUGIN_SE="$root/bin/age-plugin-se"
export AGENIX_SE_KEYGEN="$root/bin/keygen"
export DARWIN_REBUILD="$root/bin/darwin-rebuild"
export HOMEBREW_INSTALLER="$root/homebrew-installer"
export ID="$root/bin/id"
export UNAME="$root/bin/uname"
export SCUTIL="$root/bin/scutil"
export STAT="$root/bin/stat"
export DSCL="$root/bin/dscl"
export XCODE_SELECT="$root/bin/xcode-select"
export SUDO="$root/bin/sudo"
export SYSTEM_NIX="$root/bin/nix"
export SYSTEM_DARWIN_REBUILD="$root/system/bin/darwin-rebuild"
export SYSTEM_PROFILE="$root/system/profile"
export INTEL_BREW="$root/missing-intel-brew"

# Read-only check reports blockers without creating state or identities.
BREW="$root/missing-brew" "$driver" --check --host TestWork --checkout "$root/checkout" > "$root/check.out"
test ! -e "$root/home/Library/Application Support/macos-nix-bootstrap"
test ! -e "$root/home/private/identity.txt"
grep -F 'Command Line Tools are not installed' "$root/check.out"

if "$driver" --check --host Missing >/dev/null 2>&1; then
  echo "unknown host was accepted" >&2
  exit 1
fi

# Enrollment is explicit, preserves private output, and records only public state.
printf 'yes\n' | "$driver" --prepare-enrollment --host TestWork --profile work > "$root/enroll.out"
test -f "$root/home/private/identity.txt"
grep -F 'age1se1bootstraptest' "$root/enroll.out"
state="$root/home/Library/Application Support/macos-nix-bootstrap/state.json"
test "$(jq -r .phase "$state")" = waiting-for-enrollment
if grep -q 'device identity' "$state"; then
  echo "private identity leaked into checkpoint state" >&2
  exit 1
fi

# Existing identities must remain private.
chmod 0644 "$root/home/private/identity.txt"
if "$driver" --prepare-enrollment --host TestWork >/dev/null 2>&1; then
  echo "insecure existing identity was accepted" >&2
  exit 1
fi
chmod 0600 "$root/home/private/identity.txt"

# Active console account mismatches stop before mutation.
if CONSOLE_USER=someone-else "$driver" --check --host TestWork >/dev/null 2>&1; then
  echo "inactive console user was accepted" >&2
  exit 1
fi

# Existing nix-darwin is rejected unless migration mode is explicit.
cp "$root/bin/darwin-rebuild" "$SYSTEM_DARWIN_REBUILD"
if CLT_READY=1 BREW="$root/missing-brew" "$driver" --apply --host TestWork --checkout "$root/checkout" >/dev/null 2>&1; then
  echo "existing nix-darwin was accepted without explicit migration review" >&2
  exit 1
fi
rm -f "$SYSTEM_DARWIN_REBUILD"

# Wrong/missing recipient blocks prerequisites and switching.
if AGENIX_FAIL=1 CLT_READY=1 BREW="$root/missing-brew" "$driver" --apply --host TestWork --checkout "$root/checkout" >/dev/null 2>&1; then
  echo "failed secret readiness was accepted" >&2
  exit 1
fi
test ! -e "$root/sudo.args"

# Alternate Intel Homebrew blocks native installation.
printf '#!/bin/bash\nexit 0\n' > "$root/intel-brew"
chmod +x "$root/intel-brew"
if INTEL_BREW="$root/intel-brew" CLT_READY=1 BREW="$root/missing-brew" \
  "$driver" --apply --host TestWork --checkout "$root/checkout" >/dev/null 2>&1; then
  echo "alternate Homebrew was ignored" >&2
  exit 1
fi

# Missing CLT requests the supported installer and stops before sudo/switch.
set +e
printf 'yes\n' | BREW="$root/missing-brew" "$driver" --apply --host TestWork --checkout "$root/checkout"
status=$?
set -e
test "$status" = 5
test -f "$root/clt-install-requested"
test ! -e "$root/sudo.args"

# Missing Homebrew uses the pinned installer, then a build failure still blocks sudo.
brew="$root/bin/brew"
rm -f "$brew"
set +e
printf 'yes\n' | CLT_READY=1 BREW="$brew" NIX_FAIL_BUILD=1 \
  "$driver" --apply --host TestWork --checkout "$root/checkout"
status=$?
set -e
test "$status" = 17
test -x "$brew"
test ! -e "$root/sudo.args"

# Failed activation checks and switches are recorded and never reported complete.
set +e
printf 'yes\n' | CLT_READY=1 BREW="$brew" DARWIN_CHECK_FAIL=1 \
  "$driver" --apply --host TestWork --checkout "$root/checkout"
status=$?
set -e
test "$status" != 0
test "$(jq -r .phase "$state")" = activation-check-failed

set +e
printf 'yes\nyes\n' | CLT_READY=1 BREW="$brew" DARWIN_SWITCH_FAIL=1 \
  "$driver" --apply --host TestWork --checkout "$root/checkout"
status=$?
set -e
test "$status" != 0
test "$(jq -r .phase "$state")" = activation-failed
test ! -e "$SYSTEM_DARWIN_REBUILD"

set +e
printf 'yes\nyes\n' | CLT_READY=1 BREW="$brew" PROFILE_MISMATCH=1 \
  "$driver" --apply --host TestWork --checkout "$root/checkout"
status=$?
set -e
test "$status" != 0
test "$(jq -r .phase "$state")" = verification-failed
rm -f "$SYSTEM_DARWIN_REBUILD" "$SYSTEM_PROFILE"

# Ready path asks for final confirmation, switches the exact host, and verifies Lix.
printf 'yes\nyes\n' | CLT_READY=1 BREW="$brew" "$driver" --apply --host TestWork --checkout "$root/checkout"
grep -F "$root/bin/darwin-rebuild switch --no-write-lock-file --flake $root/archived-source#TestWork" "$root/sudo.args"
test "$(jq -r .phase "$state")" = verified

# A declined final confirmation may run the approved check, but never switch.
rm -f "$root/sudo.args"
set +e
printf 'yes\nno\n' | CLT_READY=1 BREW="$brew" "$driver" --apply --allow-existing-darwin --host TestWork --checkout "$root/checkout" >/dev/null 2>&1
status=$?
set -e
test "$status" != 0
grep -F "$root/bin/darwin-rebuild check --no-write-lock-file" "$root/sudo.args"
if grep -Fq "$root/bin/darwin-rebuild switch" "$root/sudo.args"; then
  echo "declined final confirmation still switched" >&2
  exit 1
fi

echo "bootstrap software tests passed"
