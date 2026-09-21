#!/bin/bash
# Variables in command strings must expand in the child shell, not the test runner.
# shellcheck disable=SC2016
set -euo pipefail

package=$1
fish=$2
zsh=$3
root="$PWD/fixture with spaces"
mkdir -p "$root"
cp --recursive "$package" "$root/shells"
chmod --recursive u+w "$root/shells"
for file in "$root/shells/bin/"* "$root/shells/share/terraform-token/"*; do
  sed --in-place \
    --expression "s|$package|$root/shells|g" \
    --expression "s|/terraform-token-test|$root|g" "$file"
done

identity="$root/Library/Application Support/agenix/identity.txt"
mkdir -p "$(dirname "$identity")"
age-keygen --output "$identity"
recipient=$(age-keygen -y "$identity")
printf '%s\n' 'test token with $dollars; "quotes" and $(not-a-command)' >"$root/plaintext"
encrypt() {
  age --encrypt --recipient "$recipient" --output "$root/token.next.age" "$root/plaintext"
  mv "$root/token.next.age" "$root/token file.age"
}
encrypt

home="$root/home"
mkdir -p "$home/.config/fish/conf.d"
cp "$root/shells/share/terraform-token/env.fish" "$home/.config/fish/conf.d/terraform-cloud-token.fish"
for file in .zshenv .bashrc .bash_profile .profile; do
  cp "$root/shells/share/terraform-token/env.sh" "$home/$file"
done
cat >"$root/verify" <<'EOF'
#!/bin/sh
set -eu
test "$TF_TOKEN_app_terraform_io" = "$(cat "$EXPECTED_TOKEN_FILE")"
test -r "$BASH_ENV"
test -r "$ENV"
EOF
chmod +x "$root/verify"

run() {
  # A clean parent deliberately provides neither a token nor BASH_ENV.
  env --ignore-environment \
    HOME="$home" XDG_CONFIG_HOME="$home/.config" TERM=dumb \
    PATH="$root/shells/bin:$PATH" \
    EXPECTED_TOKEN_FILE="$root/plaintext" VERIFY_TOKEN="$root/verify" \
    "$@"
}

for shell in "$fish" "$zsh" "$root/shells/bin/bash" "$root/shells/bin/sh"; do
  for mode in -c -lc -ic -lic; do
    run "$shell" "$mode" '"$VERIFY_TOKEN"'
  done
done

# Native Bash's startup hooks cover login and interactive invocations too.
for mode in -lc -ic -lic; do
  run /bin/bash "$mode" '"$VERIFY_TOKEN"'
done

# Noninteractive native Bash uses BASH_ENV; native sh inherits the export.
run "$fish" -c '/bin/bash -c '\''"$VERIFY_TOKEN"'\''; and /bin/sh -c '\''"$VERIFY_TOKEN"'\'''
run "$zsh" -c '/bin/bash -c '\''"$VERIFY_TOKEN"'\'' && /bin/sh -c '\''"$VERIFY_TOKEN"'\'''
run "$root/shells/bin/bash" --noprofile --norc -c '"$VERIFY_TOKEN"'
run env TF_TOKEN_app_terraform_io=stale "$fish" -c '"$VERIFY_TOKEN"'
run env TF_TOKEN_app_terraform_io=stale "$zsh" -c '"$VERIFY_TOKEN"'

# Each new shell reads the current ciphertext, without agenix or launchd.
printf '%s\n' rotated-token >"$root/plaintext"
encrypt
run "$fish" -c '"$VERIFY_TOKEN"'
run "$zsh" -c '"$VERIFY_TOKEN"'
run "$root/shells/bin/bash" -c '"$VERIFY_TOKEN"'

# Failures must be visible and must not leave an inherited stale credential.
mv "$root/token file.age" "$root/token.saved.age"
run env TF_TOKEN_app_terraform_io=stale "$fish" -c 'not set --query TF_TOKEN_app_terraform_io' 2>"$root/errors"
grep --fixed-strings 'Unable to decrypt the Terraform Cloud token' "$root/errors"
run env TF_TOKEN_app_terraform_io=stale "$zsh" -c 'test -z "${TF_TOKEN_app_terraform_io+x}"' 2>"$root/errors"
grep --fixed-strings 'Unable to decrypt the Terraform Cloud token' "$root/errors"

: >"$root/plaintext"
encrypt
if "$root/shells/bin/read-terraform-cloud-token" >"$root/output" 2>"$root/errors"; then
  echo 'empty token was accepted' >&2
  exit 1
fi
test ! -s "$root/output"
grep --fixed-strings 'Terraform Cloud token is empty' "$root/errors"
printf 'Terraform token shell startup tests passed\n'
