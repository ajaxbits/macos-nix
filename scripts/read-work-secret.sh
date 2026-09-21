#!/bin/sh
set -eu

# BASH_ENV must not recursively initialise the subprocesses used to load it.
unset BASH_ENV ENV
export PATH="@pluginPath@:$PATH"

secret=$(@age@ --decrypt --identity @identity@ @encrypted@) || {
  printf 'Unable to decrypt work shell secret %s\n' @description@ >&2
  exit 1
}
if [ -z "$secret" ]; then
  printf 'Work shell secret %s is empty\n' @description@ >&2
  exit 1
fi
printf '%s' "$secret"
