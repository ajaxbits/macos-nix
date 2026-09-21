#!/bin/sh
set -eu

# BASH_ENV must not recursively initialise the subprocesses used to load it.
unset BASH_ENV ENV
export PATH="@pluginPath@:$PATH"

token=$(@age@ --decrypt --identity @identity@ @encrypted@) || {
  echo 'Unable to decrypt the Terraform Cloud token for this shell' >&2
  exit 1
}
if [ -z "$token" ]; then
  echo 'Terraform Cloud token is empty' >&2
  exit 1
fi
printf '%s' "$token"
