# Fish shell (homeManager aspect)
{ inputs, lib, ... }:
let
  mkRebuildFunction =
    {
      checkout,
      outputName,
      buildExe,
      sudoExe,
      rebuildExe,
    }:
    ''
      if test (count $argv) -ne 0
        echo "nixre does not accept arguments" >&2
        return 2
      end

      set -l flake_location ${lib.escapeShellArg checkout}
      set -l output_name ${lib.escapeShellArg outputName}

      ${buildExe} build \
        --accept-flake-config \
        --no-write-lock-file \
        "$flake_location#darwinConfigurations.$output_name.system"
      or return $status

      ${sudoExe} ${rebuildExe} switch \
        --no-write-lock-file \
        --flake "$flake_location#$output_name"
    '';
in
{
  options.macosNix.mkRebuildFunction = lib.mkOption {
    type = lib.types.raw;
    readOnly = true;
  };
  config = {
    macosNix.mkRebuildFunction = mkRebuildFunction;

    flake.aspects.fish.homeManager =
      {
        config,
        pkgs,
        lib,
        ...
      }:
      let
        inherit (lib.meta) getExe;
        inherit (config.macosNix) host;
        jj = getExe pkgs.jujutsu;
        sd = getExe pkgs.sd;
      in
      {
        home.packages = [ pkgs.fishPlugins.gruvbox ];

        programs = {
          zoxide = {
            enable = true;
            enableFishIntegration = true;
            enableZshIntegration = true;
            enableBashIntegration = true;
          };

          starship = {
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

          fish = {
            enable = true;
            functions = {
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
                ${mkRebuildFunction {
                  checkout = host.flakeDirectory;
                  outputName = host.outputName;
                  buildExe = getExe pkgs.nix-output-monitor;
                  sudoExe = "/usr/bin/sudo";
                  rebuildExe = getExe inputs.darwin.packages.${pkgs.stdenv.hostPlatform.system}.darwin-rebuild;
                }}
              '';
            };

            shellAliases = {
              v = "nvim";
              l = "${pkgs.eza}/bin/eza -lahF --git --no-user --group-directories-first --color-scale";
              la = "${pkgs.eza}/bin/eza -lahF --git";
              cat = "${pkgs.bat}/bin/bat -pp";
            };

            interactiveShellInit = ''
              fish_vi_key_bindings
              set fish_greeting
              set fish_cursor_insert line

              ${pkgs.any-nix-shell}/bin/any-nix-shell fish --info-right | source
            '';
          };
        };
      };
  };
}
