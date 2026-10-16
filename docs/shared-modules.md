# Shared Home Manager Modules

This flake exports portable user configuration through `modules.homeManager`.
Consumers may use a different Home Manager/Nixpkgs pin; packages are resolved
from the consumer's module arguments, not the macOS host package set.

| Export | Behavior |
| --- | --- |
| `coreutils` | CLI packages, Atuin, direnv/nix-direnv, eza, jq, lazygit and fzf |
| `fish-common` | Fish preferences/helpers, aliases, Gruvbox, zoxide and Starship |
| `vcs-common` | Git/LFS defaults, Delta and jj workflow/preferences |
| `terminal-common` | Ghostty appearance, fonts, notifications and shell integration |

Import individual modules, not this repository's profiles or recursive module
tree. Its feature files are flake-parts modules, not standalone Home Manager
modules. A flake-aspects consumer can use ordinary class-level imports:

```nix
{ inputs, ... }:
{
  flake.aspects.fish.homeManager = {
    imports = [ inputs.shared.modules.homeManager.fish-common ];
  };
}
```

The consumer supplies the user/home/state version, Git identity, terminal
package, actual font installation, platform-specific shortcuts, editor and
rebuild function. Shared Git/jj reads identity from
`programs.git.settings.user`. CLI features such as fzf require `fd` on PATH;
the source's Darwin system package list is not part of `coreutils`.

The Mac-facing `fish`, `vcs` and `terminal` modules compose these exports with
their existing host-specific settings. They are not portable exports.

The Fedora consumer is `../nixos-asahi`. While developing across both checkouts,
use `--override-input shared path:/absolute/path/to/macos-nix` with
`--no-write-lock-file`. Publish the source exports before pinning the consumer
to a remote revision; do not persist local paths in its lock file. Sharing
configuration does not share secrets, browser state or runtime credentials.
