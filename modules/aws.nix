# AWS IAM Identity Center tooling for work machines.
{ lib, ... }:
{
  flake.aspects.aws-work.homeManager =
    { pkgs, ... }:
    let
      inherit (lib) getExe;
      aws = getExe pkgs.awscli2;
      fzf = getExe pkgs.fzf;
    in
    {
      home.packages = [ pkgs.awscli2 ];

      programs.fish.functions.aws-profile = {
        description = "Select the AWS profile used by this shell";
        body = ''
          argparse 'h/help' 'c/clear' -- $argv
          or return 2

          if set -q _flag_help
            printf '%s\n' \
              'usage: aws-profile [profile]' \
              '       aws-profile --clear'
            return 0
          end

          if set -q _flag_clear
            if test (count $argv) -gt 0
              echo "aws-profile: --clear does not accept a profile" >&2
              return 2
            end

            set --erase AWS_PROFILE AWS_DEFAULT_PROFILE
            set --erase AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY
            set --erase AWS_SESSION_TOKEN AWS_SECURITY_TOKEN
            echo "Cleared the AWS environment for this shell"
            return 0
          end

          if test (count $argv) -gt 1
            echo "usage: aws-profile [profile]" >&2
            return 2
          end

          set -l profiles (${aws} configure list-profiles)
          or return $status

          if test (count $profiles) -eq 0
            echo "No AWS profiles are configured; run 'aws configure sso' first." >&2
            return 1
          end

          set -l profile
          if test (count $argv) -eq 1
            if not contains -- $argv[1] $profiles
              echo "Unknown AWS profile: $argv[1]" >&2
              return 2
            end
            set profile $argv[1]
          else
            set profile (printf '%s\n' $profiles | ${fzf} --prompt='AWS profile> ' --height=40% --reverse)
            or return $status
          end

          # Explicit credentials take precedence over profiles in the AWS
          # credential chain, so remove stale values before selecting SSO.
          set --erase AWS_DEFAULT_PROFILE
          set --erase AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY
          set --erase AWS_SESSION_TOKEN AWS_SECURITY_TOKEN
          set --global --export AWS_PROFILE $profile

          echo "Using AWS profile '$profile' in this shell"
        '';
      };
    };
}
