#!/bin/sh
# Sourced by shell startup files and noninteractive Bash via BASH_ENV.
export BASH_ENV='@shellEnv@'
export ENV="$BASH_ENV"

@secretInit@
unset _work_secret_value

@extra@
