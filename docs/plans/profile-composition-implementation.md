# Profile Composition And Host Metadata

## Goal

Replace automatic enable-everything host assembly with explicit foundation,
personal, and work compositions. Centralize host/account facts, perform the
approved obsolete-configuration cleanup as a separate change, and establish
evaluation checks that protect the profile boundary.

This is the first production-repository implementation step after the successful
Secure Enclave prototype. It does not deploy the work Mac or migrate secrets.
Do not use Superpowers skills or workflows.

## Design Authority

Read `docs/plans/profile-boundaries.md` first. It contains the current user
decisions, including changes that supersede the original prototype plan:

- OpenCode2 will be Nix-managed with writable configuration in both profiles.
- Kagi will use one shared encrypted credential, with distinct device identities.
- Other work credentials are not automatically shared. OpenAI is excluded.
- Tailscale keeps the standalone `tailscale-app` implementation with a convenient
  CLI. Do not enable the separate `tailscaled` service.
- Fantastical and Drafts are foundational; Bitwarden is personal only.
- Containers are a shared capability with different implementations: personal
  Podman and work Docker Desktop, installed and updated by MDM.
- Slack is also MDM-owned. No Nix/Brew installation of Slack or work Docker Desktop.
- tmux is a basic foundation package, without legacy configuration or plugins.
- Yojam is work-only. Exclude Spotify, Talon, xbar, jfrog-cli, Maven, CocoaPods,
  mpv, Apple container, Homerow, and VS Code.
- Delete Syncthing and inactive target-repository configuration assets.

The destination policy is not a mandate to implement every feature in this task.
The current personal OpenCode configuration, secret delivery, and existing package
versions must remain unchanged until their dedicated follow-on changes.

## Safety And Scope

- Do not switch either system, activate Home Manager, restart applications, enroll
  keys, read plaintext credentials, decrypt/rekey secrets, or change network state.
- Do not change `flake.lock` or add a new framework/dependency for profile wiring.
- Do not run the current `nixre` helper: it selects a fixed checkout/host and a
  moving nix-darwin reference.
- Do not edit `~/.dotfiles` or other worktrees. They contain existing user/agent
  changes and the current work laptop's source configuration.
- Do not delete user application data, synchronized folders, or out-of-repository
  keys. Configuration/ciphertext removal below does not authorize those actions.
- Do not commit or push unless requested. Do not stage unrelated work.
- A new nonexcluded file under `modules/` is automatically loaded by import-tree.
  Keep every such file a flake-parts module.

At handoff, this workspace is a detached worktree of `ajaxbits/macos-nix`; planning
documents are untracked. Recheck current status. The prototype implementation and
results were in sibling worktree `../shiny-wolf`; OpenCode changes were also in
`../macos-nix`. Read them if useful, but do not copy their entire worktrees or
overwrite local work. Prototype consolidation can be a separate reviewed change;
this structural task does not depend on activating its packages or test agents.

## Deliverables

| File | Responsibility |
| --- | --- |
| `modules/profiles.nix` (new) | Explicit named foundation, personal, and work compositions for Darwin and Home Manager |
| `modules/hosts.nix` | Centralized host/account inventory and explicit selection of profile modules |
| `modules/user.nix` | Shared shell/account mechanics without independently hardcoded personal account facts |
| `modules/brew.nix` | Shared Brew policy/application selection separated from personal additions |
| `modules/coreutils.nix` | General tools remain shared; seventeenlands belongs to personal |
| `modules/fish.nix` | Host-aware rebuild inputs; no accidental activation of unfinished work helpers |
| `modules/vcs.nix` | Shared Git/jj mechanics with identity supplied from centralized configuration |
| `modules/nix.nix`, `modules/macos-defaults.nix` | Host platform and state-version facts no longer independently hardcoded |
| `modules/secretive.nix`, `modules/secrets.nix` | Derive paths from the configured user/home; preserve existing personal secret delivery |
| `modules/profile-checks.nix` (new) | Evaluation-only profile and host-isolation checks; no deployable fake work host |
| `docs/plans/profile-composition-results.md` (new) | Baseline comparison, verification results, and explicit deferred work |

Keep existing feature files where possible. Do not rewrite the repository into a
host-centric directory hierarchy or create a large generic capability framework.
Use a small flake-level host inventory and lexical bindings/custom flake-parts
options as needed; avoid spreading the same metadata across `specialArgs` maps.

## Implementation Sequence

### 1. Capture The Existing Personal Baseline

Inspect current repository instructions and changes. Resolve root input pins
through the root map in `flake.lock`, not unsuffixed transitive node names.

The existing real output is `darwinConfigurations.Alexs-MacBook-Air`, using user
`ajax`, home `/Users/ajax`, UID `501`, Darwin state version `5`, and Home Manager
state version `22.05`. Verify those facts before relying on them.

Record a narrow, secret-free evaluation snapshot containing:

- Hostname/platform, primary user, managed account fields, home, state versions.
- Git/jj identity and configuration, Fish functions/aliases, terminal settings.
- System/Home Manager package selections, Brew casks/formulae and activation policy.
- Enabled agents/services, AeroSpace settings, secret names and runtime paths only.
- Relevant generated-file content or hashes, without decrypting anything.

Evaluate the system derivation as well:

```sh
nix eval --no-write-lock-file --raw '.#darwinConfigurations.Alexs-MacBook-Air.system.drvPath'
```

Do not dump the entire evaluated configuration or shell environment. Store paths
can change with source-tree hashes; compare effective settings/content rather
than treating every derivation-hash change as a behavioral regression.

### 2. Perform Approved Cleanup As A Separate Checkpoint

Delete the following tracked assets after confirming they have no active consumer:

- `modules/_disabled/syncthing.nix`.
- `secrets/syncthing/cert.age` and `secrets/syncthing/key.age`.
- The two matching Syncthing rules in `secrets/secrets.nix`.
- `modules/_disabled/README.md` if it has no remaining purpose after cleanup.
- The unreferenced `modules/terminal/zellij-config.kdl`.

Remove Homerow and VS Code casks, plus the commented-out Talon/Tor Browser casks,
from `modules/brew.nix`. Do not decrypt ciphertext before deletion. Do not remove
historical documentation merely because it mentions an intentionally retired tool.

There is no WezTerm, Sketchybar, or Linux-builder implementation in this target
repo to delete. Do not import those assets or their keys from the legacy source.

Verify references and reevaluate the personal configuration. Expected changes are
limited to the approved removed declarations; Syncthing/Zellij were inactive.
Capture a post-cleanup baseline for the structural refactor. Keep the cleanup
diff separately reviewable from the wiring changes.

### 3. Introduce Explicit Profile Composition Atomically

Replace BOTH `builtins.attrValues` imports in `modules/hosts.nix` when introducing
profile aggregates. Otherwise the new aggregates would all become enabled on the
personal host, or could recursively import themselves.

Create named `foundation`, `personal`, and `work` modules in both module classes.
Personal and work import their class's foundation plus their selected additions.
A host imports one profile per class, not all registry values. Adding a new
registered aspect must not activate it unless a selected composition imports it.

Separate the current mixed features with the smallest edits:

- General CLI tools are foundation; seventeenlands is personal.
- Shared casks are foundation; Bitwarden, personal knowledge/browser apps, games,
  imaging tools, and Podman Desktop are selected by personal.
- `ebooks` and `podman` are selected by personal, never work. In particular, work
  must not receive Podman-provided `docker` or `docker-compose` executables.
- Work represents an external MDM Docker prerequisite, not a request to install
  Docker Desktop, replace its CLI, or start its daemon. Likewise for Slack.
- Keep Fantastical and `tailscale-app` selected in foundation. Preserve existing
  app routes during this refactor; route redesign is a later behavioral change.
- Do not add Drafts, tmux, Yojam, new fonts, or new Tailscale CLI behavior yet.
  Their approved installation/integration work follows this structural task.
- Preserve the existing personal OpenCode module and Kagi declaration in the
  personal composition temporarily. Do not apply that generated configuration or
  its legacy private-key-path requirement to work. The later shared OpenCode2 and
  hardware-backed-secrets implementation will replace this temporary placement.
- Do not silently enable the dormant/broken work Fish functions merely by removing
  their hardcoded personal guard. Keep them out of the selected work composition
  until the work-tooling change repairs them and supplies their dependencies.

These temporary placements preserve shipped personal behavior; do not build a
backward-compatibility framework around them. Document precisely what is still
missing from work, and do not advertise the work composition as deployment-ready.

Preserve personal Brew cleanup/upgrade settings at this stage. Make any work
fixture use non-destructive cleanup and no automatic upgrades, without changing
personal's existing policy or taking over MDM-owned applications.

### 4. Centralize Host And Account Facts

Use one small host record per real configuration, keeping the output key distinct
from physical hostname. The record should contain only facts actually consumed:

- Profile (`personal` or `work`), architecture, physical hostname.
- Username, full name, home directory, UID/account-management policy where needed.
- Git name/email, Darwin and Home Manager state versions.
- Explicit rebuild checkout location/selector where the helper needs them.

Keep only the existing personal machine as a real deployable output for now. The
new Mac's actual account facts and work Git identity have not been supplied. Do
not substitute Aphrodite's facts or guess an email/UID.

Pass facts into lower-level configurations through ordinary host-module values
and lexical bindings. Generic Home Manager features should use the configured
`home.homeDirectory`; generic Darwin features can use the configured primary
user/account record. No generic feature should independently assume `/Users/ajax`.

Preserve the current personal values exactly. Keep Git and jj identities in sync.
Reject missing or placeholder identities for a configured real work host; permit
explicitly labeled synthetic identities only in nondeployable test fixtures.

Keep the existing personal `bitwarden` identity filename and encrypted Kagi source
unchanged. Deriving that path from the actual configured home is in scope;
switching it to a new Secure Enclave identity is not.

### 5. Make Rebuild Selection Safe

Treat this as an explicit safety change, not a behavior-neutral rename. The helper
must build and switch the same configured checkout and exact output, with correct
quoting and failure propagation. A failed build must never invoke the switch.

Use the repository-pinned nix-darwin implementation or the corresponding built
system's rebuild executable; verify the available attribute/executable at the
locked revision. Do not retain `nix-darwin/master` as an independent moving input.

Test helper argument handling, paths containing spaces, selected output, and
build-failure behavior with stub commands. No tests may run real sudo or perform
a real switch. Preserve existing personal checkout intent unless the user
explicitly chooses a different canonical checkout; do not automatically point
deployment at the implementing agent's temporary worktree.

### 6. Add Boundary And Regression Checks

Use evaluation-only fixtures for two different usernames, home directories, and
profiles. Keep fake machine outputs out of `darwinConfigurations` and any normal
switch command. Test the actual profile/host assembly logic, not a second copy of
the lists constructed only for tests.

Required checks:

| Check | Expected outcome |
| --- | --- |
| Personal post-cleanup baseline | Same effective packages, casks, services, identities, and generated behavior, except the explicitly reviewed rebuild safety change |
| Explicit selection | Registering an unselected marker aspect does not change either fixture |
| Foundation | Both fixtures receive the selected shared components |
| Personal-only selection | Work excludes Bitwarden, hobby apps, seventeenlands, ebooks, Podman Desktop, Podman/Compose/vfkit and Docker-name wrappers |
| MDM ownership | Neither fixture declares installation of Slack or work Docker Desktop |
| No retired components | No active Syncthing/legacy configuration references or forbidden app/formula declarations |
| Paths | A fixture for another user has no `/Users/ajax` leaks in user-specific settings |
| Work staging | Work does not require the old personal bitwarden key or activate the existing generated OpenCode configuration |
| Identity validation | Missing/placeholder real work identity fails clearly; Git and jj share the configured identity |
| Rebuild helper | Same checkout/output, safe quoting, and no switch after failed build |

Run `nix flake check --no-write-lock-file` and force the real personal host's
system derivation. Build that system on a compatible macOS builder if feasible,
without activating it. Report evaluation and build results separately.

New untracked files are not automatically included by Git-backed flake evaluation.
Use an intentional, reviewed source snapshot or selective tracking. `path:.` can
include untracked files but must not capture private fixtures, credentials, or
unrelated local material. Inspect the source tree before using it.

### 7. Report And Stop Before Activation

Write `docs/plans/profile-composition-results.md` with:

- Files changed and the cleanup versus structural versus rebuild-safety changes.
- The finalized profile/host assembly model and concrete selected features.
- Baseline comparison and test/build outcomes, including unrun checks.
- Explicit temporary personal OpenCode/secrets placement and unfinished work areas.
- Remaining real work-host facts needed before exposing a deployment output.
- Confirmation that no activation, credential migration, network change, MDM
  application management, lockfile update, or unrelated-worktree edit occurred.

## Subsequent Tasks

After this change is reviewed, separate implementation tasks can:

1. Add approved app/CLI deltas: Drafts, basic tmux, a Tailscale app CLI, fonts, Yojam,
   and repaired AWS/Jira/Terraform workflows. Keep MDM ownership intact.
2. Promote the successful age prototype into production secret loading, choose
   recovery custody/retention, and integrate mutable OpenCode2 with one startup
   owner and an explicit rotation/restart path.
3. Validate the persistent login arrangement with dummy credentials and an
   approved real fresh-login/reboot transition.
4. Enroll production recipients, share Kagi deliberately, migrate work tokens,
   supply the new Mac's host facts, and review an actual rollout separately.
5. Implement the final first-switch bootstrap described in
   [New Mac First-Switch Bootstrap](new-mac-bootstrap-spec.md). Its only
   preinstalled third-party dependency is Nix installed through the Lix installer.
   The bootstrap must obtain its tools, handle missing platform prerequisites,
   pause/resume for recipient enrollment, and perform an explicitly approved first
   switch. This is a later deployment feature, not permission to activate a system
   during the structural task above.

No additional profile framework or sops-nix migration is necessary for this task.
