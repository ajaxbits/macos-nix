{ pkgs, ... }:
let
  inherit (pkgs.lib.meta) getExe;
  jj = getExe pkgs.jujutsu;
  sd = getExe pkgs.sd;
in
{
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    settings = {
      aws.disabled = true;
      custom = {
        jjstate = {
          when = "${jj} --ignore-working-copy root";
          command = ''
            ${jj} log -r@ -n1 --ignore-working-copy --no-graph -T "" --stat | tail -n1 | sd "(\d+) files? changed, (\d+) insertions?\(\+\), (\d+) deletions?\(-\)" ' ${1}m ${2}+ ${3}-' | ${sd} " 0." ""
          '';
        };
      };
    };
  };
}
