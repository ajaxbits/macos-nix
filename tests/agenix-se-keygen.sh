#!/bin/bash
set -euo pipefail

driver=$1
root=$(mktemp -d "${TMPDIR:-/tmp}/agenix-se-keygen-test.XXXXXX")
trap 'rm -rf -- "$root"' EXIT

cat > "$root/plugin" <<'EOF'
#!/bin/bash
set -euo pipefail
test "$1" = keygen
test "$2" = --access-control=none
test "$3" = -o
printf 'device-bound-identity\n' > "$4"
printf 'Public key: age1se1testrecipient\n'
EOF
chmod +x "$root/plugin"

identity="$root/private directory/identity.txt"
AGE_PLUGIN_SE="$root/plugin" "$driver" "$identity" > "$root/output"
test "$(/usr/bin/stat -f '%Lp' "$(dirname "$identity")")" = 700
test "$(/usr/bin/stat -f '%Lp' "$identity")" = 600
test "$(cat "$identity.recipient")" = age1se1testrecipient
grep -F 'Public recipient: age1se1testrecipient' "$root/output"

if AGE_PLUGIN_SE="$root/plugin" "$driver" "$identity" >/dev/null 2>&1; then
  echo "existing identity was overwritten" >&2
  exit 1
fi
test "$(cat "$identity")" = device-bound-identity

if AGE_PLUGIN_SE="$root/plugin" "$driver" relative/path >/dev/null 2>&1; then
  echo "relative identity path was accepted" >&2
  exit 1
fi

mkdir "$root/open-parent"
chmod 0755 "$root/open-parent"
if AGE_PLUGIN_SE="$root/plugin" "$driver" "$root/open-parent/identity" >/dev/null 2>&1; then
  echo "group/world-readable identity parent was accepted" >&2
  exit 1
fi

cat > "$root/bad-plugin" <<'EOF'
#!/bin/bash
set -euo pipefail
printf 'private material\n' > "$4"
printf 'unexpected output\n'
EOF
chmod +x "$root/bad-plugin"
if AGE_PLUGIN_SE="$root/bad-plugin" "$driver" "$root/bad/identity" >/dev/null 2>&1; then
  echo "malformed recipient output was accepted" >&2
  exit 1
fi
test ! -e "$root/bad/identity"
test ! -e "$root/bad/identity.recipient"

mkdir -m 0700 "$root/locked"
mkdir -m 0700 "$root/locked/identity.lock"
if AGE_PLUGIN_SE="$root/plugin" "$driver" "$root/locked/identity" >/dev/null 2>&1; then
  echo "concurrent enrollment lock was ignored" >&2
  exit 1
fi
