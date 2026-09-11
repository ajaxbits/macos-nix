#!/bin/bash
set -euo pipefail
umask 077

if test "$#" -ne 1; then
  echo "usage: agenix-se-keygen ABSOLUTE_IDENTITY_PATH" >&2
  exit 2
fi

identity_path=$1
recipient_path="${identity_path}.recipient"
plugin=${AGE_PLUGIN_SE:?AGE_PLUGIN_SE must name age-plugin-se}

case "$identity_path" in
  /*) ;;
  *) echo "identity path must be absolute" >&2; exit 2 ;;
esac

test ! -e "$identity_path" || { echo "refusing to overwrite $identity_path" >&2; exit 1; }
test ! -e "$recipient_path" || { echo "refusing to overwrite $recipient_path" >&2; exit 1; }

parent=$(dirname -- "$identity_path")
if test ! -e "$parent"; then
  mkdir -p "$parent"
  chmod 0700 "$parent"
fi
test -d "$parent" || { echo "identity parent is not a directory" >&2; exit 1; }
test "$(/usr/bin/stat -f '%u' "$parent")" = "$(id -u)" || { echo "identity parent must be user-owned" >&2; exit 1; }
parent_mode=$(/usr/bin/stat -f '%Lp' "$parent")
test $((8#$parent_mode & 077)) -eq 0 || { echo "identity parent must not grant group/other access" >&2; exit 1; }

lock="${identity_path}.lock"
mkdir -m 0700 "$lock" 2>/dev/null || { echo "identity enrollment is already running" >&2; exit 1; }
scratch=$(mktemp -d "$parent/.agenix-se-keygen.XXXXXX")
published_recipient=0
cleanup() {
  if test "$published_recipient" = 1 && test ! -e "$identity_path"; then
    rm -f -- "$recipient_path"
  fi
  rm -rf -- "$scratch" "$lock"
}
trap cleanup EXIT INT TERM

"$plugin" keygen --access-control=none -o "$scratch/identity" \
  | sed -n 's/^Public key: //p' > "$scratch/recipient"

test "$(grep -c '^age1se1' "$scratch/recipient")" -eq 1 || {
  echo "age-plugin-se did not return exactly one Secure Enclave recipient" >&2
  exit 1
}
test "$(wc -l < "$scratch/recipient" | tr -d ' ')" -eq 1 || {
  echo "age-plugin-se returned unexpected recipient output" >&2
  exit 1
}

chmod 0600 "$scratch/identity" "$scratch/recipient"
test ! -e "$identity_path" && test ! -e "$recipient_path" || {
  echo "identity output appeared during enrollment; refusing to overwrite it" >&2
  exit 1
}
mv "$scratch/recipient" "$recipient_path"
published_recipient=1
# Publish private material last so interruption cannot leave an identity without
# the public recipient needed to enroll or recover it.
mv "$scratch/identity" "$identity_path"
published_recipient=0

echo "Secure Enclave identity created at $identity_path"
echo "Public recipient: $(cat "$recipient_path")"
