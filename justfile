# Secrets management for macos-nix
# Requires: agenix CLI (fetched via nix run)

default:
    @just --list

secrets_dir := "secrets"
identity := "~/.ssh/bitwarden"
agenix := "nix run github:ryantm/agenix --"

# Derive and print your SSH public key (paste into secrets/secrets.nix)
pubkey:
    ssh-keygen -y -f {{identity}}

# Edit an existing secret (e.g. `just edit-secret github_token`)
edit-secret name:
    cd {{secrets_dir}} && RULES=./secrets.nix {{agenix}} -e {{name}}.age -i {{identity}}

# Decrypt a secret to stdout (for inspection)
show-secret name:
    cd {{secrets_dir}} && RULES=./secrets.nix {{agenix}} -d {{name}}.age -i {{identity}}

# Rekey all secrets after changing recipients in secrets/secrets.nix
rekey:
    cd {{secrets_dir}} && RULES=./secrets.nix {{agenix}} -r -i {{identity}}
