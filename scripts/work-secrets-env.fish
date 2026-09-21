set --global --export BASH_ENV '@shellEnv@'
set --global --export ENV "$BASH_ENV"

@secretInit@

@extra@
