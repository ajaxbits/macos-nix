#!/bin/sh
# Sourced by shell startup files and noninteractive Bash via BASH_ENV.
export BASH_ENV='@shellEnv@'
export ENV="$BASH_ENV"

if _terraform_cloud_token=$('@reader@'); then
  export TF_TOKEN_app_terraform_io="$_terraform_cloud_token"
else
  unset TF_TOKEN_app_terraform_io
fi
unset _terraform_cloud_token
