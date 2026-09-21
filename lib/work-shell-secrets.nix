{
  pkgs,
  identityPath,
  secrets,
  posixExtra ? "",
  fishExtra ? "",
}:
let
  inherit (pkgs) lib;
  validName = name: builtins.match "[A-Za-z_][A-Za-z0-9_]*" name != null;
  secretNames = builtins.attrNames secrets;
  readers = lib.mapAttrs (
    name: encryptedFile:
    pkgs.replaceVars ../scripts/read-work-secret.sh {
      age = lib.getExe pkgs.age;
      pluginPath = "${pkgs.age-plugin-se}/bin";
      identity = lib.escapeShellArg identityPath;
      encrypted = lib.escapeShellArg (toString encryptedFile);
      description = lib.escapeShellArg name;
    }
  ) secrets;
  posixSecretInit = lib.concatMapStringsSep "\n" (name: ''
    if _work_secret_value=$('WORK_SHELL_SECRETS_PACKAGE/bin/read-${name}'); then
      export ${name}="$_work_secret_value"
    else
      unset ${name}
    fi
  '') secretNames;
  fishSecretInit = lib.concatMapStringsSep "\n" (name: ''
    if set --local work_secret_value ('WORK_SHELL_SECRETS_PACKAGE/bin/read-${name}')
        set --global --export ${name} "$work_secret_value"
    else
        set --erase ${name}
    end
  '') secretNames;
in
assert lib.assertMsg (lib.all validName secretNames)
  "work shell secret names must be valid environment variables";
pkgs.runCommand "work-shell-secrets"
  {
    nativeBuildInputs = [
      pkgs.shellcheck
      pkgs.fish
    ];
  }
  ''
    export HOME="$TMPDIR/fish-home"
    mkdir -p "$HOME" "$out/bin" "$out/share/work-shell-secrets"
    ${lib.concatMapStringsSep "\n" (name: ''
      cp '${readers.${name}}' "$out/bin/read-${name}"
    '') secretNames}
    substitute ${../scripts/work-secrets-env.sh} "$out/share/work-shell-secrets/env.sh" \
      --subst-var-by secretInit ${lib.escapeShellArg posixSecretInit} \
      --subst-var-by extra ${lib.escapeShellArg posixExtra} \
      --subst-var-by shellEnv "$out/share/work-shell-secrets/env.sh"
    substitute ${../scripts/work-secrets-env.fish} "$out/share/work-shell-secrets/env.fish" \
      --subst-var-by secretInit ${lib.escapeShellArg fishSecretInit} \
      --subst-var-by extra ${lib.escapeShellArg fishExtra} \
      --subst-var-by shellEnv "$out/share/work-shell-secrets/env.sh"
    sed -i "s|WORK_SHELL_SECRETS_PACKAGE|$out|g" \
      "$out/share/work-shell-secrets/env.sh" \
      "$out/share/work-shell-secrets/env.fish"

    # Bash and sh have no startup file for a standalone noninteractive shell.
    for shell in bash sh; do
      case "$shell" in
        bash) executable=${pkgs.bashInteractive}/bin/bash ;;
        sh) executable=/bin/sh ;;
      esac
      substitute ${../scripts/work-secrets-shell.sh} "$out/bin/$shell" \
        --subst-var-by shellEnv "$out/share/work-shell-secrets/env.sh" \
        --subst-var-by shell "$executable"
    done
    chmod +x "$out/bin/"*
    fish_indent --write "$out/share/work-shell-secrets/env.fish"
    shellcheck "$out/bin/"* "$out/share/work-shell-secrets/env.sh"
    fish --no-config --no-execute "$out/share/work-shell-secrets/env.fish"
    fish_indent --check "$out/share/work-shell-secrets/env.fish"
  ''
