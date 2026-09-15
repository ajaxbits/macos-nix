# Yazi

Yazi is enabled in both Home Manager profiles as a lightweight, navigation-first file manager. Run `y` to open the current directory or `y <path>` to start elsewhere. `q` exits and changes the calling shell to Yazi's final directory; `Q` exits without changing it.

## Navigation

| Key | Action |
| --- | --- |
| `/` | Smart-filter names in the current listing; a unique directory is entered automatically and a file match opens |
| `f` | Ordinary filter of the current listing; it does **not** enter a directory automatically |
| `F` | Jump to a file by its starting character |
| `z` | Jump using the existing zoxide directory history; Yazi visits update that history |
| `Z` | Fuzzy-find files and directories beneath the current directory |
| `H` / `L` | Back / forward directory history |
| `g h` | Home directory |
| `g c` | `~/.config` |
| `g d` | `~/Downloads` |
| `g p` | `~/code` |
| `g Space` | Interactive path entry |
| `s` / `S` | Recursive filename search via fd / recursive content search via ripgrep |

`/` narrows the current listing rather than moving between matches as Vim's `/` does. Use `j` and `k` in the narrowed listing; `n` and `N` remain Yazi's native find navigation and do not cycle smart-filter results. Recursive discovery is handled by `Z` and `s`, while `S` searches file contents.

The built-in preview keeps folders, text/code, JSON, archives, and metadata useful. Image, video, PDF, and font rendering and media thumbnail preloading are disabled. MIME lookup uses filename and extension tables first, with `file` fallback for unknown names; a misleading recognized extension can still result in an incorrect MIME classification.

The Gruvbox dark flavor is selected for both terminal appearance modes, with plain separators and icon-free UI overrides suited to the configured font.
