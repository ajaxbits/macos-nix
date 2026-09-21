{ pkgs }:
{
  posix = ''
    if [ "''${JFROG_USERNAME+x}" = x ] && [ "''${JFROG_TOKEN+x}" = x ]; then
      _jfrog_username_encoded=$(printf '%s' "$JFROG_USERNAME" | ${pkgs.jq}/bin/jq --slurp --raw-input --raw-output @uri)
      _jfrog_token_encoded=$(printf '%s' "$JFROG_TOKEN" | ${pkgs.jq}/bin/jq --slurp --raw-input --raw-output @uri)
      export PIP_INDEX_URL="https://$_jfrog_username_encoded:$_jfrog_token_encoded@upside.jfrog.io/upside/api/pypi/upside-python/simple"
      export PIP_INDEX="$PIP_INDEX_URL"
      export UV_INDEX_JFROG_USERNAME="$JFROG_USERNAME"
      export UV_INDEX_JFROG_PASSWORD="$JFROG_TOKEN"
      unset _jfrog_username_encoded _jfrog_token_encoded
    else
      unset PIP_INDEX_URL PIP_INDEX UV_INDEX_JFROG_USERNAME UV_INDEX_JFROG_PASSWORD
    fi
  '';
  fish = ''
    if set --query JFROG_USERNAME JFROG_TOKEN
        set --local jfrog_username_encoded (printf '%s' "$JFROG_USERNAME" | ${pkgs.jq}/bin/jq --slurp --raw-input --raw-output @uri)
        set --local jfrog_token_encoded (printf '%s' "$JFROG_TOKEN" | ${pkgs.jq}/bin/jq --slurp --raw-input --raw-output @uri)
        set --global --export PIP_INDEX_URL "https://$jfrog_username_encoded:$jfrog_token_encoded@upside.jfrog.io/upside/api/pypi/upside-python/simple"
        set --global --export PIP_INDEX "$PIP_INDEX_URL"
        set --global --export UV_INDEX_JFROG_USERNAME "$JFROG_USERNAME"
        set --global --export UV_INDEX_JFROG_PASSWORD "$JFROG_TOKEN"
    else
        set --erase PIP_INDEX_URL PIP_INDEX UV_INDEX_JFROG_USERNAME UV_INDEX_JFROG_PASSWORD
    end
  '';
}
