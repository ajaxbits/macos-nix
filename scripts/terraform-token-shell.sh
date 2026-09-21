#!/bin/sh
# Bootstrap shells that do not read startup files in noninteractive mode.
# shellcheck source=/dev/null
. '@shellEnv@'
exec '@shell@' "$@"
