# Profile Composition Implementation Results

## Status

The scoped profile-composition implementation is complete in this worktree and
verified without activation. The existing personal host remains the only real
`darwinConfigurations` output. The work profile is exercised only through private
evaluation fixtures and is intentionally not deployment-ready.

No system switch, Home Manager activation, credential decryption/rekey, key
enrollment, service restart, network change, MDM application management, lockfile
update, commit, push, or unrelated-worktree edit was performed.

## Changes

### Approved cleanup

- Removed disabled Syncthing configuration, its two ciphertext files, and their
  recipient rules. No ciphertext was decrypted.
- Removed the empty `_disabled` documentation and unused Zellij KDL asset.
- Removed Homerow and Visual Studio Code casks and stale Talon/Tor Browser comments.
- Did not modify user Syncthing data, installed applications, `~/.dotfiles`, or
  inactive legacy assets outside this repository.

### Explicit composition

`modules/profiles.nix` now defines explicit Darwin and Home Manager modules named:

- `foundation`
- `personal`, which imports `foundation` plus personal additions
- `work`, which imports `foundation` and remains deliberately sparse

`modules/hosts.nix` selects exactly one profile per module class. The former
registry-wide `builtins.attrValues` imports are gone. Registered modules no longer
become active merely because import-tree discovers them.

Current initial selection:

| Class | Foundation | Personal additions | Work staging |
| --- | --- | --- | --- |
| Darwin | host/user, Nix/Lix, macOS defaults, shared Brew casks, general utilities, AeroSpace, terminal integration, Secretive | personal Brew casks, ebooks, Podman, existing OpenCode overlay, existing Agenix import | foundation only |
| Home Manager | host/user, general utilities, Fish, Ghostty, Git/jj | seventeenlands, existing OpenCode configuration, existing personal Kagi/Agenix configuration | foundation only |

The work fixture therefore has no Podman/Compose/vfkit or Docker-name wrappers,
Bitwarden, hobby apps, seventeenlands, ebooks, old personal Kagi identity, or
existing generated OpenCode configuration. It declares neither MDM Docker Desktop
nor MDM Slack.

### Host metadata

The existing personal facts now live in one host record and are injected into
both Darwin and Home Manager evaluations. Generic modules consume configured
metadata rather than independently assuming `/Users/ajax`, the hostname, profile,
state version, Git identity, or checkout location.

The current real values remain:

| Fact | Value |
| --- | --- |
| Output and hostname | `Alexs-MacBook-Air` |
| Profile | `personal` |
| Platform | `aarch64-darwin` |
| User/home/UID | `ajax`, `/Users/ajax`, `501` |
| Darwin/Home Manager state versions | `5`, `22.05` |
| Git and jj | `Alex Jackson`, `git@ajaxbits.com` |
| Rebuild checkout | `/Users/ajax/code/macos-nix` |

Managed users require a UID. Real work hosts reject empty or placeholder Git/jj
identity. Synthetic fixtures can provide explicit test identities without becoming
deployable outputs.

### Brew and package boundaries

Shared casks are AnkerWork, Barkeep, BetterDisplay, Fantastical, Firefox, Ice,
KeepingYouAwake, Maccy, Rocket, Shottr, Tailscale, and VLC. Personal adds the
remaining retained personal casks. Personal retains cleanup `zap` and automatic
upgrade; work staging uses cleanup `none` and no automatic upgrade.

General command-line packages remain foundation. `seventeenlands` moved to a
personal-only Home Manager aspect. Personal continues to select the existing
Podman feature; work does not.

### Rebuild safety

The generated `nixre` function now derives checkout/output from host facts, builds
the exact `darwinConfigurations.<output>.system`, stops immediately after build
failure, and switches the same checkout/output with the rebuild executable from
the repository-pinned nix-darwin input. It no longer fetches
`nix-darwin/master` independently. It rejects unsupported positional arguments.

This helper was tested only with stub commands. It was not run against sudo or an
actual system switch.

## Checks

`modules/profile-checks.nix` uses the same host constructor and actual profile
modules as the real host. Its synthetic personal/work evaluations are private
values, not `darwinConfigurations` outputs.

The checks cover:

- An unselected marker aspect does not enter either profile.
- Foundation features appear in both fixtures.
- Personal packages, casks, secrets, OpenCode configuration, and containers do
  not enter work.
- MDM-owned/retired casks and excluded legacy formulae are absent.
- Alternate user paths do not leak `/Users/ajax`.
- Git and jj use the same host identity.
- Placeholder identity fails for a real work host.
- Personal/work Homebrew activation policies differ as intended.
- Rebuild arguments preserve spaces, use the same checkout/output, reject unknown
  arguments, and never call the switch stub after a failed build.

## Verification Evidence

The following completed successfully from the repository root using `path:.` so
the untracked new modules were included:

```sh
nix flake check --no-write-lock-file 'path:.'
nix eval --no-write-lock-file --raw \
  'path:.#darwinConfigurations.Alexs-MacBook-Air.system.drvPath'
nix build --no-write-lock-file --no-link \
  'path:.#darwinConfigurations.Alexs-MacBook-Air.system'
```

The complete personal Darwin system built successfully on this Mac. The build
produced `/nix/store/5ckkylbc4k536fk434r74ncilvk8il87-darwin-system-26.11.15abb8c.drv`
for the final source snapshot at build time. No activation was run.

`git diff --check` passed after formatting touched Nix files with the formatter
from the locked nixpkgs revision. `flake.lock` remained unchanged.

Observed non-fatal warnings:

- The existing configuration or dependencies still evaluate deprecated `system`
  references in some paths.
- The personal cache default endpoint did not identify itself as a binary cache.
- Garnix DNS resolution failed during checks/build; Nix continued with available
  local/other cache sources.
- Flake-parts exposes `modules` and `homeModules`, which generic flake checking
  reports as unknown custom outputs.

## Personal Baseline

Before cleanup, the personal system derivation was:

```text
/nix/store/x3gfvlg0hmyjpy93ygj7g0sivhr4d40d-darwin-system-26.11.15abb8c.drv
```

After structural changes, source/store paths changed as expected. Narrow
evaluation confirmed the retained personal account, state versions, Git/jj
identity, Fish function set, aliases, Ghostty settings, Kagi secret name/path
metadata, OpenCode enablement, launch agents, package selections, and Homebrew
policy. Differences are the approved removals, list/order changes from explicit
module composition, and the intentional rebuild-helper safety behavior.

## Deferred Work

The work profile is not ready to deploy. It intentionally lacks:

- A real host record, username/home/UID management decision, hostname, and work
  Git email.
- Drafts, basic tmux, Atkinson font installation, the Tailscale standalone-app CLI,
  and Yojam.
- Repaired AWS/Jira/Terraform/Upside shell workflows and their dependencies. The
  previously dormant functions were removed from the foundation rather than
  activating known-broken behavior; legacy source/history remains available for
  the follow-on implementation.
- Nix-managed OpenCode2 with writable configuration in both profiles and the
  work-only Upside marketplace bridge.
- Secure Enclave identity enrollment, Kagi recipient rekeying, work credential
  ciphertext, recovery custody, and plaintext retention policy. Plugin-aware
  agenix is implemented in the follow-on production age change; no OpenCode
  startup coordinator was approved or added.
- Persistent fresh-login/reboot validation with dummy credentials.
- The final new-Mac bootstrap and explicitly reviewed first switch.

Cache trust and any employer policy differences also remain separate review items.
The current flake-level personal cache configuration was not changed in this task.
