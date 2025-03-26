{ pkgs, ... }:
{
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    enableNushellIntegration = true;
    settings = {
      aws.disabled = true;
      custom = {
        jjstate = {
          command = ''
            ${pkgs.jujutsu}/bin/jj log -r@ -l1 --no-graph -T "" --stat | tail -n1 | awk '{print $1 "m", $4 "+", $6 "-"}'
          '';
          detect_folders = [ ".jj" ];
        };
      };
    };
  };
}
