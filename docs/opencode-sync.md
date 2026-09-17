# OpenCode Upside skills

The work profile installs and updates a Nix-declared set of plugins from
Upside's Claude Code marketplace, then exposes their skills through OpenCode's
global automatic-discovery directory.

## Architecture

```text
plugin list in modules/opencode.nix
              |
              v
Claude CLI: register marketplace, install, update
              |
              v
~/.config/opencode/skills/upside/<plugin> -> <Claude install>/skills
              |
              v
OpenCode global skill discovery
```

Nix owns the plugin **selection**. Claude's supported plugin CLI owns
installation and version resolution. OpenCode owns skill discovery. The sync
does not manage OpenCode configuration, and Claude's `enabledPlugins` settings
do not determine which skills OpenCode receives.

The declaration currently lives in `upsidePlugins` in `modules/opencode.nix`.
Add or remove names there to change the managed set.

## Commands

| Command | Purpose |
|---|---|
| `claude-update-upside-plugins` | Register or refresh `upside-official`, install missing declared user-scope plugins, and update installed ones |
| `opencode-sync-upside-skills` | Work offline from Claude's local installation inventory and publish skill links |
| `opencode-refresh-upside-skills` | Run update followed by sync; this is the normal manual entry point |

The `opencode-upside-sync` launch agent runs the refresh command at load and
hourly. Logs are written to:

```text
~/Library/Logs/opencode-upside-sync.out.log
~/Library/Logs/opencode-upside-sync.err.log
```

All three commands use one lock. A concurrent manual or scheduled run exits
without changing published links.

## Selection behavior

- Adding a declaration installs it on the next refresh.
- Deleting a declared installation causes the next refresh to restore it.
- Removing a declaration removes its OpenCode link but does not uninstall it
  from Claude.
- Disabling a plugin in Claude does not remove it from OpenCode; Nix remains the
  OpenCode source of truth.
- Manually installed, undeclared plugins are left alone.
- A plugin such as `hooks` that has no `skills/` directory remains installed
  for Claude but is skipped by the linker.

Only a user-scope installation satisfies the declaration. Project, local, and
managed installations do not substitute for the user installation maintained
by this feature.

## Discovery and publication

OpenCode V2 recursively discovers `SKILL.md` files beneath
`~/.config/opencode/skills`, so no explicit `skills` source is required. The
linker owns only this subtree:

```text
~/.config/opencode/skills/upside/
```

Each link points directly to a plugin's `skills/` directory, preserving nearby
scripts, templates, and references. Publication is staged in a sibling
directory. If inventory parsing, installation resolution, or link generation
fails, the previously published directory is retained. Successful publication
uses removal/rename replacement; it is not an atomic directory exchange.

An update failure prevents that run's link publication. Updates completed
before the failure remain installed, and the next hourly run retries the full
refresh.

## Authentication

The marketplace is private. Claude uses Git's configured authentication for
explicit marketplace and plugin commands. The marketplace itself is registered
through SSH. Its plugin manifests use HTTPS GitHub URLs, so the generated
commands apply a process-local `https://github.com/` to `git@github.com:` Git
rewrite. This keeps plugin clones on the same SSH authentication path without
changing global Git configuration or coupling Git access to the separate `gh`
token.

The generated commands also share one temporary SSH control connection for the
duration of a refresh. The first Git operation may request Secretive approval;
later plugin operations reuse that connection instead of requesting approval
again. The connection and its private control-socket directory are closed and
removed when the command exits, including after an error or interruption.

Ensure the work account can access the marketplace and a representative plugin
without an interactive prompt:

```sh
git ls-remote git@github.com:upside-services/ai-marketplace.git HEAD
git ls-remote git@github.com:upside-services/ai-agent-platform.git HEAD
```

The generated command environment includes `git`, but it does not embed
credentials, consume `gh` authentication, or load interactive shell startup
files. Authentication errors are logged and retried at the next run.

## Verify

```sh
# Run the complete operation now.
opencode-refresh-upside-skills

# Check scheduling and logs.
launchctl list | grep opencode-upside-sync
tail -n 100 ~/Library/Logs/opencode-upside-sync.err.log

# Inspect generated links and discovered skill files.
ls -l ~/.config/opencode/skills/upside/
find -L ~/.config/opencode/skills/upside -name SKILL.md | wc -l

# Verify the declared user-scope installations.
claude plugin list --json \
  | jq -r '.[] | select(.scope == "user" and (.id | endswith("@upside-official"))) | .id'
```

After the first refresh, start a new OpenCode session and verify a
representative Upside skill can be loaded. Skill discovery is automatic; this
feature does not promise that every already-running session immediately reloads
all changes.

## Migration from the vendor source

The previous implementation generated `~/.config/opencode/vendor/upside` and
required an explicit OpenCode `skills` entry.

1. Rebuild and activate the work configuration.
2. Run `opencode-refresh-upside-skills`.
3. Remove only the old `~/.config/opencode/vendor/upside` entry from the
   user-owned `skills` array in `~/.config/opencode/opencode.json`.
4. Remove the old generated `~/.config/opencode/vendor/upside` directory.
5. Start a new OpenCode session and verify representative skills.

The automation deliberately does not edit the user-owned OpenCode config or
delete the legacy path.

## Troubleshooting

### Marketplace source conflict

The updater refuses to replace an existing marketplace named
`upside-official` when it does not point to
`upside-services/ai-marketplace`. Inspect it with:

```sh
claude plugin marketplace list --json
```

Resolve the conflicting registration manually, then rerun the refresh.

### Authentication failure

Run the `git ls-remote` command above. If it prompts or fails, repair GitHub or
SSH credentials before retrying. Existing OpenCode links remain available.

### A declared plugin is not linked

Run the update and sync commands separately to isolate network maintenance from
local publication:

```sh
claude-update-upside-plugins
opencode-sync-upside-skills
```

Check `claude plugin list --json` for exactly one user-scope installation and
confirm its `installPath` exists. A log message ending in `(no skills/)` is an
expected skip.

## Validation

```sh
nix flake check
```

The checks use a stub Claude executable and temporary home directory. They
cover fresh installation, updates, marketplace conflicts, malformed inventory,
declaration removal, paths containing spaces, lock contention, empty
declarations, and preservation of unrelated skills.
