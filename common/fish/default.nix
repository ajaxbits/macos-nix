{ pkgs, hostname, ... }:
{
  imports = [
    ./starship.nix
    ./zoxide.nix
  ];

  programs.fish = {
    enable = true;
    functions = {
      __fish_command_not_found_handler = {
        body = "__fish_default_command_not_found_handler $argv[1]";
        onEvent = "fish_command_not_found";
      };
      take = # fish
        ''
          set dir $argv[1]
          mkdir -p $dir
          cd $dir
        '';
    } // (import ./functions.nix { inherit hostname; });

    shellAbbrs = {
      "lg" = "lazygit";
    };

    shellAliases = {
      v = "nvim";
      l = "${pkgs.eza}/bin/eza -lahF --git --no-user --group-directories-first --color-scale";
      la = "${pkgs.eza}/bin/eza -lahF --git";
      cat = "${pkgs.bat}/bin/bat -pp";
    };

    shellInit = # fish
      ''
        fish_vi_key_bindings
        set fish_greeting
        set fish_cursor_insert line

        ${pkgs.any-nix-shell}/bin/any-nix-shell fish --info-right | source
        ${pkgs.jujutsu}/bin/jj util completion fish | source
      '';
  };
}
