# Yazi

Yazi is enabled in both Home Manager profiles as a lightweight, navigation-first file manager. Run `y` to open the current directory or `y <path>` to start elsewhere. `q` exits and changes the calling shell to Yazi's final directory; `Q` exits without changing it.

## Navigation

| Key | Action |
| --- | --- |
| `/` or `f` | Live-filter names in the current listing; Enter finishes typing without opening a result |
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

### Filtering without surprises

1. Press `/` and type part of a name. The current directory listing narrows as you type; even a single matching directory stays put.
2. Press Enter to finish the filter. While the input is open, `j` and `k` are text input, not file navigation.
3. Use `j`/`k` to choose a result, `l` to enter a directory, or Enter to open a file. Opening a directory with `l` keeps you in Yazi; the directory's default editor opener can launch Neovim/Oil with Enter.
4. Escape closes an active input directly. Once back in the file list, Escape clears the filter (and may first clear another active selection/search state).

Filtering uses smart-case regular-expression matching, not fuzzy matching: lowercase queries ignore case, uppercase queries make matching case-sensitive, and regex punctuation has special meaning. Use `Z` for fuzzy matching beneath the current directory, or `z` for directory-history jumps.

Unlike Vim's `/`, filtering hides nonmatches rather than moving the cursor through the complete listing. `n`/`N` belong to Yazi's native find action and do not cycle filter results. Recursive discovery is handled by `Z` and `s`, while `S` searches file contents.

### Zoxide history

Yazi records directory changes in the same zoxide database used by the shell. Enter a directory with `l`; simply hovering over it and seeing its preview does not record a visit. The `z` picker excludes your current directory, so leave with `h` before looking for the directory you just visited.

To check whether a visit was recorded independently of the picker, run `zoxide query -l` in the shell. Restart Yazi after activating configuration changes so its initialization hooks are reloaded.

## Working with Neovim and Oil

- From the shell, use `y` and `z` to reach a project, then open a text file with Enter. Yazi runs the configured `EDITOR=nvim` and waits; quit Neovim to return to Yazi.
- Inside Neovim, **Space → o → t** opens Oil at the current file's parent directory. This is your existing mapping; `-` is already mapped to a horizontal split in your Neovim config.
- Use Oil for nearby browsing and editing directory entries. Save an Oil buffer with `:w` to apply file operations; your Neovim config explicitly excludes Oil from auto-save. Ordinary Vim `/` and `n`/`N` work inside Oil.
- To start directly in Oil, navigate to a project with Yazi, press `q`, then run `nvim .`. The `y` shell wrapper leaves the shell in that project directory.
- An existing Neovim session in another terminal is independent: opening a file from shell-launched Yazi starts another Neovim process. Use Oil in the existing session when you want to keep its buffers and windows.

The built-in preview keeps folders, text/code, JSON, archives, and metadata useful. Image, video, PDF, and font rendering and media thumbnail preloading are disabled. MIME lookup uses filename and extension tables first, with `file` fallback for unknown names; a misleading recognized extension can still result in an incorrect MIME classification.

The Gruvbox dark flavor is selected for both terminal appearance modes. File-icon lookup tables and completion icons are disabled so default devicon glyphs and their separate color palette do not clash with the configured font and theme; status and tab separators are plain.
