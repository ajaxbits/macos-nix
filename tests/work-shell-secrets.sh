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
for file in "$root/shells/bin/"* "$root/shells/share/work-shell-secrets/"*; do
  sed --in-place \
    --expression "s|$package|$root/shells|g" \
    --expression "s|/work-shell-secrets-test|$root|g" "$file"
done

terraform_token='test token with $dollars; "quotes" and $(not-a-command)'
jfrog_username='alex+build@upside.com'
jfrog_token='jfrog/token+$with:special@characters'
write_secret() {
  local value=$1 output=$2
  printf '%s\n' "$value" >"$output"
  chmod 400 "$output"
}
write_secret "$terraform_token" "$root/terraform token"
write_secret "$jfrog_username" "$root/jfrog username"
write_secret "$jfrog_token" "$root/jfrog token"

if grep --recursive --extended-regexp 'age-plugin-se|age --decrypt|read-(JFROG|TF_TOKEN)' "$root/shells"; then
  echo 'shell startup package still contains a decryption command' >&2
  exit 1
fi

home="$root/home"
mkdir -p "$home/.config/fish/conf.d"
cp "$root/shells/share/work-shell-secrets/env.fish" "$home/.config/fish/conf.d/work-shell-secrets.fish"
for file in .zshenv .bashrc .bash_profile .profile; do
  cp "$root/shells/share/work-shell-secrets/env.sh" "$home/$file"
done
cat >"$root/verify" <<'EOF'
#!/bin/sh
set -eu
test "$TF_TOKEN_app_terraform_io" = "$EXPECTED_TERRAFORM_TOKEN"
test "$JFROG_USERNAME" = "$EXPECTED_JFROG_USERNAME"
test "$JFROG_TOKEN" = "$EXPECTED_JFROG_TOKEN"
test "$UV_INDEX_JFROG_USERNAME" = "$JFROG_USERNAME"
test "$UV_INDEX_JFROG_PASSWORD" = "$JFROG_TOKEN"
expected_url='https://alex%2Bbuild%40upside.com:jfrog%2Ftoken%2B%24with%3Aspecial%40characters@upside.jfrog.io/upside/api/pypi/upside-python/simple'
test "$PIP_INDEX_URL" = "$expected_url"
test "$PIP_INDEX" = "$PIP_INDEX_URL"
test -r "$BASH_ENV"
test -r "$ENV"
EOF
chmod +x "$root/verify"

run() {
  env --ignore-environment \
    HOME="$home" XDG_CONFIG_HOME="$home/.config" TERM=dumb \
    PATH="$root/shells/bin:$PATH" \
    EXPECTED_TERRAFORM_TOKEN="$terraform_token" \
    EXPECTED_JFROG_USERNAME="$jfrog_username" \
    EXPECTED_JFROG_TOKEN="$jfrog_token" \
    VERIFY_SECRETS="$root/verify" "$@"
}

for shell in "$fish" "$zsh" "$root/shells/bin/bash" "$root/shells/bin/sh"; do
  for mode in -c -lc -ic -lic; do
    run "$shell" "$mode" '"$VERIFY_SECRETS"'
  done
done
for mode in -lc -ic -lic; do
  run /bin/bash "$mode" '"$VERIFY_SECRETS"'
done

run "$fish" -c '/bin/bash -c '\''"$VERIFY_SECRETS"'\''; and /bin/sh -c '\''"$VERIFY_SECRETS"'\'''
run "$zsh" -c '/bin/bash -c '\''"$VERIFY_SECRETS"'\'' && /bin/sh -c '\''"$VERIFY_SECRETS"'\'''
run "$root/shells/bin/bash" --noprofile --norc -c '"$VERIFY_SECRETS"'

# New shells read rotated plaintext rather than retaining an old value.
terraform_token=rotated-token
chmod 600 "$root/terraform token"
write_secret "$terraform_token" "$root/terraform token"
run "$fish" -c '"$VERIFY_SECRETS"'
run "$zsh" -c '"$VERIFY_SECRETS"'
run "$root/shells/bin/bash" -c '"$VERIFY_SECRETS"'

# A missing JFrog token unsets stale token-dependent values without suppressing
# independently decryptable work secrets.
mv "$root/jfrog token" "$root/jfrog-token.saved"
run env JFROG_TOKEN=stale PIP_INDEX_URL=stale "$fish" -c \
  'set --query TF_TOKEN_app_terraform_io; and set --query JFROG_USERNAME; and not set --query JFROG_TOKEN; and not set --query PIP_INDEX_URL'

: >"$root/jfrog token"
run env JFROG_TOKEN=stale PIP_INDEX_URL=stale "$fish" -c \
  'not set --query JFROG_TOKEN; and not set --query PIP_INDEX_URL'
printf 'Work shell secret startup tests passed\n'
