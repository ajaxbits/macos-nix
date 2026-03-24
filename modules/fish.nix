# Fish shell (homeManager aspect)
{ ... }:
let
  profile = "personal";
in
{
  flake.modules.homeManager.fish =
    { pkgs, lib, ... }:
    let
      inherit (lib.modules) mkIf mkMerge;
      inherit (lib.meta) getExe getExe';
      hostName = "Alexs-MacBook-Air";
      jj = getExe pkgs.jujutsu;
      sd = getExe pkgs.sd;

      workFunctions =
        let
          aws = getExe' pkgs.awscli2 "aws";
          gh = getExe pkgs.gh;
          aws_sso_url = "https://upside-services.awsapps.com/start";
          aws_sso_region = "us-east-1";
          aws_profile_region_default = "us-east-1";
        in
        {
          upclone = ''
            set repo $argv[1]
            mkdir -p ~/code
            ${gh} repo clone upside-services/$repo ~/code/$repo
            cd ~/code/$repo
            ${jj} git init --colocate
            ${jj} branch track main@origin
            ${jj} branch track master@origin
          '';
          aws-config = ''
            echo "
            +-------------+
            | 1: SSO info |
            +-------------+
            | - SSO start URL: ${aws_sso_url}
            | - SSO region:    ${aws_sso_region}
            +--------------------------------+
            | 2: Browser challenge/response  |
            +--------------------------------+
            | 3: Choose account & role       |
            +--------------------------------+
            | 4: CLI defaults & profile name |
            +--------------------------------+
            | - Client Region: ${aws_profile_region_default} probably best
            | - Output format: json, text, table, yaml, yaml-stream (depends on your workflow)
            | - Profile name:  Pick something memorable (like \"prod-[role]\" for 337)
            +---+
            "
            ${aws} configure sso
            echo "
            +-------------------------------------------+
            | Pssst, or you could just use \`aws-env\`... |
            +-------------------------------------------+
            "
          '';
          aws-env = ''
            set -l options 'h/help'
            argparse -n aws-env $options -- $argv

            if set -q _flag_help
              echo "this is where help would be if I had any"
              return 1
            end

            set profile ""

            set profile (grep profile "$HOME/.aws/config" | grep -v default | ${pkgs.fzf}/bin/fzf | cut -d ' ' -f 2 | string replace -r -a '[()\]\[]+' "")

            echo "#Loading AWS environment variables for \"$profile\" profile"
            for value in (echo (aws2-wrap --profile "$profile" --export) | sd " export" "\nexport" | sd "export " "" | sd "=" " ")
              eval "set -gx $value"
            end
          '';
          aws-login = ''
            set -l options 'h/help'
            argparse -n aws-login $options -- $argv

            if set -q _flag_help
              echo "this is where help would be if I had any"
              return 1
            end

            set profile ""

            if count $argv > /dev/null; set profile "$1"
            else
              set profile (grep profile "$HOME/.aws/config" | grep -v default | ${pkgs.fzf}/bin/fzf | cut -d ' ' -f 2 | string replace -r -a '[()\]\[]+' "")
            end

            ${aws} sso login --profile "$profile"
            aws-env "$profile"
          '';
        };
    in
    {
      home.packages = [ pkgs.fishPlugins.gruvbox ];

      programs.zoxide = {
        enable = true;
        enableFishIntegration = true;
        enableZshIntegration = true;
        enableBashIntegration = true;
      };

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
                ${jj} log -r@ -n1 --ignore-working-copy --no-graph -T "" --stat | tail -n1 | ${sd} "(\d+) files? changed, (\d+) insertions?\(\+\), (\d+) deletions?\(-\)" ' ''${1}m ''${2}+ ''${3}-' | ${sd} " 0." ""
              '';
            };
          };
        };
      };

      programs.fish = {
        enable = true;
        functions = mkMerge [
          {
            __fish_command_not_found_handler = {
              body = "__fish_default_command_not_found_handler $argv[1]";
              onEvent = "fish_command_not_found";
            };
            take = ''
              set dir $argv[1]
              mkdir -p $dir
              cd $dir
            '';
            t = ''
              if test -z $argv[1]
                  set dirname xx
              else
                  set dirname $argv[1]
              end
              pushd (mktemp -d -t $dirname.XXXX)
            '';
            nixre = ''
              set flakeLocation ~/code/macos-nix

              nom build \
                --accept-flake-config \
                $flakeLocation/.#darwinConfigurations.${hostName}.system

              sudo nix run \
                --accept-flake-config \
                nix-darwin/master#darwin-rebuild -- \
                    switch --flake $flakeLocation/.
            '';
          }
          (mkIf (profile == "work") workFunctions)
        ];

        shellAliases = {
          v = "nvim";
          l = "${pkgs.eza}/bin/eza -lahF --git --no-user --group-directories-first --color-scale";
          la = "${pkgs.eza}/bin/eza -lahF --git";
          cat = "${pkgs.bat}/bin/bat -pp";
        };

        shellAbbrs = mkIf (profile == "work") {
          b = "./build.sh";
        };

        shellInit = ''
          fish_vi_key_bindings
          set fish_greeting
          set fish_cursor_insert line

          ${pkgs.any-nix-shell}/bin/any-nix-shell fish --info-right | source
          ${pkgs.jujutsu}/bin/jj util completion fish | source

          theme_gruvbox dark
        '';
      };
    };
}
