{ config, ... }:
let
  hostName = config.networking.hostName or "unknown";
in
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
