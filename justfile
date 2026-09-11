# Secrets management for macos-nix
# Tools are built from this flake's locked inputs.

default:
    @just --list

secrets_dir := "secrets"
identity := env_var_or_default("AGENIX_IDENTITY", env_var("HOME") + "/.ssh/bitwarden")
agenix := "nix run .#agenix --"

# Derive and print your SSH public key (paste into secrets/secrets.nix)
pubkey:
    ssh-keygen -y -f "{{identity}}"

# Edit an existing secret (e.g. `just edit-secret github_token`)
edit-secret name:
    cd {{secrets_dir}} && RULES=./secrets.nix {{agenix}} -e {{name}}.age -i "{{identity}}"

# Decrypt a secret to stdout (for inspection)
show-secret name:
    cd {{secrets_dir}} && RULES=./secrets.nix {{agenix}} -d {{name}}.age -i "{{identity}}"

# Rekey all secrets after changing recipients in secrets/secrets.nix
rekey:
    cd {{secrets_dir}} && RULES=./secrets.nix {{agenix}} -r -i "{{identity}}"

# Create an unattended, device-bound Secure Enclave identity. Refuses overwrite.
new-se-identity path:
    nix run .#agenix-se-keygen -- "{{path}}"

# Print the public recipient for an existing Secure Enclave identity.
se-recipient path:
    nix run .#age-plugin-se -- recipients -i "{{path}}"
