{
  pkgs,
  identityPath,
  encryptedFile,
}:
let
  inherit (pkgs) lib;
  reader = pkgs.replaceVars ../scripts/read-terraform-cloud-token.sh {
    age = lib.getExe pkgs.age;
    pluginPath = "${pkgs.age-plugin-se}/bin";
    identity = lib.escapeShellArg identityPath;
    encrypted = lib.escapeShellArg (toString encryptedFile);
  };
in
pkgs.runCommand "terraform-token-shells"
  {
    nativeBuildInputs = [
      pkgs.shellcheck
      pkgs.fish
    ];
  }
  ''
    export HOME="$TMPDIR/fish-home"
    mkdir -p "$HOME"
    mkdir -p "$out/bin" "$out/share/terraform-token"
    cp ${reader} "$out/bin/read-terraform-cloud-token"
    substitute ${../scripts/terraform-token-env.sh} "$out/share/terraform-token/env.sh" \
      --subst-var-by reader "$out/bin/read-terraform-cloud-token" \
      --subst-var-by shellEnv "$out/share/terraform-token/env.sh"
    substitute ${../scripts/terraform-token-env.fish} "$out/share/terraform-token/env.fish" \
      --subst-var-by reader "$out/bin/read-terraform-cloud-token" \
      --subst-var-by shellEnv "$out/share/terraform-token/env.sh"

    # Bash and sh have no startup file for a standalone noninteractive shell.
    # PATH entry points bootstrap those shells even from an old GUI process.
    for shell in bash sh; do
      case "$shell" in
        bash) executable=${pkgs.bashInteractive}/bin/bash ;;
        sh) executable=/bin/sh ;;
      esac
      substitute ${../scripts/terraform-token-shell.sh} "$out/bin/$shell" \
        --subst-var-by shellEnv "$out/share/terraform-token/env.sh" \
        --subst-var-by shell "$executable"
    done
    chmod +x "$out/bin/"*
    shellcheck "$out/bin/"* "$out/share/terraform-token/env.sh"
    fish --no-config --no-execute "$out/share/terraform-token/env.fish"
    fish_indent --check "$out/share/terraform-token/env.fish"
  ''
