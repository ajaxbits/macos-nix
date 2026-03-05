{
  config,
  lib,
  pkgs,
  profile,
  ...
}:
let
  inherit (lib.modules) mkIf mkMerge;
  inherit (lib.meta) getExe getExe';
  hostName = config.networking.hostName or "unknown";

  aws = getExe' pkgs.awscli2 "aws";
  gh = getExe pkgs.gh;
  jj = getExe pkgs.jujutsu;

  aws_sso_url = "https://upside-services.awsapps.com/start";
  aws_sso_region = "us-east-1";
  aws_profile_region_default = "us-east-1";

in
mkMerge [
  {
    t = # fish
      ''
        if test -z $argv[1]
            set dirname xx
        else
            set dirname $argv[1]
        end
        pushd (mktemp -d -t $dirname.XXXX)
      '';
    nixre = # fish
      ''
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
  (mkIf (profile == "work") {
    upclone = ''
      set repo $argv[1]
      mkdir -p ~/code
      ${gh} repo clone upside-services/$repo ~/code/$repo
      cd ~/code/$repo
      ${jj} git init --colocate
      ${jj} branch track main@origin
      ${jj} branch track master@origin
    '';
    # For interactively configuring your aws config profiles
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
      | - Profile name:  Pick something memorable (like "prod-[role]" for 337)
      +---+
      "
      ${aws} configure sso
      echo "
      +-------------------------------------------+
      | Pssst, or you could just use \`aws-env\`... |
      +-------------------------------------------+
      "
    '';

    # For switching your aws-specific shell envs for use by awscli, terraform, etc
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

    # For refreshing your aws API token (also switches aws env)
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
  })
]
