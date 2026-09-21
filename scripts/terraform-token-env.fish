set --global --export BASH_ENV '@shellEnv@'
set --global --export ENV "$BASH_ENV"

if set --local terraform_cloud_token ('@reader@')
    set --global --export TF_TOKEN_app_terraform_io "$terraform_cloud_token"
else
    set --erase TF_TOKEN_app_terraform_io
end
