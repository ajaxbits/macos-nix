# Foundation, Personal, And Work Boundaries

Status: updated with the user's component decisions. Explicitly marked review
items remain open. This records the target configuration and approved removal
scope; implementation and activation remain separate steps.

Do not use Superpowers for this work.

## Composition Model

Confirmed architecture:

```text
personal host = host/account facts + foundation + personal additions
work host     = host/account facts + foundation + work additions
```

- Foundation means enabled on both profiles by default, not merely reusable code.
- Optional capabilities can be reusable without being included in foundation.
- A foundational capability can have profile-specific implementations: personal
  uses Podman, while work relies on MDM-installed Docker Desktop.
- A profile selects features; it does not isolate processes or scrub application
  state, credentials, histories, or unmanaged files when changed.
- Each feature can contribute Darwin and Home Manager configuration together.
- Keep import-tree discovery, but replace host-level import-all with explicit
  named module selection in both classes.
- Putting a file in a `work/` directory does not restrict its scope. Work-specific
  additions must contribute to a separately selected aspect, not extend an aspect
  automatically used by personal.
- Use ordinary module composition. Do not build personal globally and remove it
  from work with large `mkForce` overrides or introduce a generic profile framework.

## Confirmed Policies

| Area | Decision |
| --- | --- |
| Profiles | Separate personal and work profiles with a reviewable shared foundation |
| OpenCode | Both use Nix-managed OpenCode2 with user/application-owned writable configuration and plugins |
| Organization integration | Upside marketplace bridge and work-specific integrations belong to work |
| Secrets | Agenix plus age-plugin-se; unattended Secure Enclave use with access control `none` |
| SSH | Secretive remains the SSH solution; age uses a separate Secure Enclave identity |
| Credential boundaries | Work-only secrets remain restricted to work; explicitly shared Kagi credential is available to both profiles |
| Kagi | One shared credential, not separate account selection or duplicate token copies per profile |
| Shared applications | Fantastical, Tailscale, and Drafts are foundational |
| Tailscale implementation | Keep `tailscale-app` with convenient CLI integration; no switch to the CLI-only daemon |
| Bitwarden | Personal only |
| MDM ownership | Work Docker Desktop and Slack are installed/updated by MDM; Nix must not manage their installation |
| Containers | Foundational capability with personal Podman and work Docker Desktop implementations |
| tmux | Foundation package only; no persistence plugins, session automation, or legacy configuration |
| Yojam | Work only |
| Removed applications | Homerow and VS Code entirely; remove the other legacy-addition GUI apps Spotify, Talon, and xbar |
| Removed legacy formulae | Do not migrate jfrog-cli, Maven, CocoaPods, mpv, or Apple container |
| Removed features | Delete Syncthing and inactive legacy configuration assets rather than retaining disabled modules |
| OpenAI | Do not migrate `OPENAI_API_KEY` |
| Production readiness | Real fresh-login/reboot behavior must be validated before credential rollout |

## Host Facts

These belong to a centralized host/account record, not a profile switch:

| Fact | Treatment |
| --- | --- |
| Configuration output name | Stable explicit rebuild selector, distinct from physical hostname |
| Physical hostname | Preserve actual or MDM-required naming |
| Username and home | Derive all user-specific paths consistently |
| UID/account ownership | Do not assume UID 501 or take over an IT-managed account |
| Architecture | Record explicitly; current support is Apple Silicon macOS |
| State versions | Preserve compatibility values; do not change them when selecting a profile |
| Repository checkout | Explicit rebuild input, not a hardcoded sibling worktree |
| Nix/MDM constraints | Verify installer ownership, policy, and permitted system changes |

Profile configuration chooses Git/jj identity and recipient selection, but their
actual values still need explicit user input. Never infer a work email or use the
current `FIXME` values. Private key material never belongs in the host record.

## Feature Matrix

Rows reflect the confirmed decisions above and the otherwise retained proposed
foundation. Items explicitly labeled review still need a decision.

| Feature | Placement | Scope and reconciliation |
| --- | --- | --- |
| flake-parts, import-tree, Home Manager wiring | Foundation | Keep current machinery; explicit host selection replaces `attrValues` imports |
| Nix/Lix tooling, GC, optimization | Foundation mechanics | Preserve personal settings initially; review work installer and trust policy separately |
| Binary caches and trusted users | Explicit policy review | Do not automatically give work trust in the personal cache; flake-level `nixConfig` applies beyond selected host modules |
| Neovim and general CLI tools | Foundation | Keep target implementation; exclude seventeenlands from general utilities |
| Fish, Starship, direnv, Atuin, fzf, zoxide | Foundation | Share behavior, not account credentials or history-sync state |
| General Fish helpers and aliases | Foundation | Keep `take`, `t`, editor/listing aliases; make rebuild helper host-aware in its own reviewed change |
| Git, Git LFS, delta, jj, lazygit | Foundation mechanics | Identity is profile-specific; preserve current aliases until individual reconciliation |
| Legacy jj/Mergiraf/PR helpers | Optional follow-on | Review individually; legacy `a` and `pull` mean different things from the target versions |
| Ghostty, Gruvbox, font selection | Foundation | Prefer target; explicitly provision Atkinson Hyperlegible Mono in a follow-on change |
| AeroSpace bindings/layout | Foundation | Keep one Nix-managed installation, not an additional Brew copy |
| AeroSpace application routing | Follow selected applications | Preserve personal routes initially; work routes must be reviewed with work app choices |
| Finder, Dock, trackpad, Caps Lock, appearance | Foundation candidate | Current behavior is largely shared; subject to work policy |
| Touch ID for sudo | Foundation | Retain native nix-darwin PAM support, separate from unattended age policy |
| Secretive and SSH agent wiring | Foundation mechanics | Host-derived paths and independently enrolled keys; do not automatically install personal SSH host access on work |
| Agenix and plugin-aware age | Foundation mechanics | Device-specific enrollment and explicit per-secret audiences, including shared Kagi; no production migration in the structural refactor |
| OpenCode2 package and runtime support | Foundation | Nix executable/service support, mutable application configuration in both profiles |
| Shared agent instructions/custom definitions | Review ownership separately | Do not assume all user-created files should become Nix-managed |
| Kagi search capability | Foundation | One credential shared by personal and work, encrypted for both enrolled devices and approved recovery recipients |
| Upside marketplace synchronization | Work | Preserve Claude-owned selection/cache and generated OpenCode skill links |
| Work MCP/provider configuration | Work | User-owned configuration; Nix supplies approved runtime tools and scoped secret delivery |
| AWS CLI, SSO helpers, aws2-wrap if retained | Work | Repair dormant helpers and add missing dependencies before enabling |
| Terraform, Jira CLI, Upside build/repository helpers | Work | Include `b`, approved clone/branch helpers, and any approved dbt shortcut; do not copy stale aliases blindly |
| Container capability | Foundation contract, profile implementations | Personal: Nix-managed Podman/Compose/vfkit and existing compatibility wrappers. Work: MDM Docker Desktop; no Podman packages, wrappers, second Docker install, or daemon ownership |
| tmux | Foundation package only | Install the basic package; no tmux.conf import, plugins, persistence, remote-session automation, or login agent |
| Ebooks and hobby tools | Personal | Calibre, Steam, Prism Launcher, seventeenlands, device-imaging apps |
| Syncthing to patroclus | Delete | Remove disabled configuration, its ciphertext and recipient rules, and obsolete references; do not delete synchronized user data |
| Inactive legacy WezTerm, Zellij, Sketchybar, Linux builder | Delete/exclude | Delete inactive assets present in this target repo; do not import them from the legacy source or copy builder key files |

The general CLI foundation currently includes curl, dust, fd, git, hck, ripgrep,
sd, uv, viddy, Neovim, bat, entr, fx, gh, jj, nix-output-monitor, xh, zoxide, eza,
jq, lazygit, and fzf. Legacy extras such as GNU coreutils, wget, gron, mosh,
diffedit3, richer bat/fzf/fx configuration, and Mergiraf can be assessed separately;
they are not prerequisites for the structural split.

## Application Matrix

These are target selections with the latest user decisions incorporated; no apps
have been installed or removed during this planning step. "Existing personal"
refers to this repo; "legacy work" refers to Aphrodite's declared Brew inventory,
not a complete inventory of manually or IT-installed apps.

| Application(s) | Target placement | Current evidence / reason |
| --- | --- | --- |
| AnkerWork, BetterDisplay | Foundation | Declared in both inventories; hardware/display utilities |
| Ice, KeepingYouAwake | Foundation | Declared in both; desktop utilities |
| Maccy, Rocket, Shottr | Foundation | Declared in both; clipboard, input, screenshot workflow; work data handling still subject to policy |
| Firefox | Foundation | Declared in both; existing browser routing |
| Fantastical | Foundation | Confirmed shared application; do not infer or configure calendar accounts |
| Homerow | Remove entirely | Remove cask declaration; do not retain as an optional feature |
| Visual Studio Code | Remove entirely | Remove cask declaration; do not retain as an optional feature |
| VLC | Foundation | Declared in both |
| Bitwarden | Personal only | No work installation or assumption that a personal vault is available during work bootstrap |
| Tailscale | Foundation | Keep tailscale-app with convenient CLI integration; enrollment/network policy is still explicit |
| Discord | Personal by default | Declared in both today; conservative proposed exclusion from new work profile unless wanted |
| Helium Browser | Personal by default | Existing personal; promote to foundation if it is part of the desired shared browser workflow |
| Notesnook, Roam Research | Personal by default | Existing personal; confirm whether either is also a work tool |
| Passepartout | Personal | Existing personal VPN application; do not infer work network configuration |
| Calibre | Personal | Existing ebooks aspect |
| Steam, Prism Launcher | Personal | Existing games/hobby apps |
| Balena Etcher, Raspberry Pi Imager | Personal | Existing device-imaging tools |
| Podman Desktop | Personal | Keep aligned with personal Podman selection, not an unconditional cask |
| Docker Desktop | Work, MDM-owned | No Nix/Brew installation, upgrade, daemon, or replacement CLI wrappers |
| Spotify | Remove from target migration | Do not import the legacy declaration |
| Talon | Remove | Remove the commented-out target declaration and do not import the legacy configuration |
| xbar | Remove from target migration | Do not import the legacy declaration |
| Yojam | Work only | Carry over its required tap/application declaration after validating current availability |
| Slack | Work, MDM-owned | No Nix/Brew installation; retaining work workspace routing does not take ownership of the app |
| Drafts | Foundation | Manage its installation through an appropriate supported channel; retain workspace routing and document any App Store bootstrap requirement |
| Apple Messages | Existing OS app | No package installation; review desired routing rather than classify an install |
| Tor Browser | Remove inactive declaration | Do not preserve the commented-out cask as a future feature |

Only Yojam is retained from the optional legacy GUI additions. The user also
explicitly excluded the following legacy formulae:

| Formula | Confirmed disposition |
| --- | --- |
| jfrog-cli, maven | Do not migrate |
| cocoapods | Do not migrate |
| container | Exclude; the selected runtimes are personal Podman and MDM work Docker Desktop |
| mpv | Do not migrate |

Homebrew mechanism and app ownership are separate. Proposed rollout policy:
non-destructive cleanup and no automatic upgrades during work onboarding. Preserve
the personal host's current policy in the initial structural-only change; any
change to that policy needs a separate intentional diff. Neither profile should
take ownership of an IT-installed app without review.

## Shared Kagi Credential

Kagi is an explicitly approved exception to separate work/personal credential
audiences. Keep one logical encrypted secret, with the recipient set consisting
of the enrolled personal and work device public keys plus approved recovery
recipients. Each Mac retains its own private device-bound identity. Both profiles
reference that ciphertext; do not duplicate the same token in two files merely
to mirror the profiles.

GitHub, Terraform Cloud, and Jira work credentials do not become shared as a
side effect. Recipient rules remain per-secret, and recovery custody still needs
an explicit decision. Older prototype documents describing blanket profile
separation are historical context; this shared-Kagi decision supersedes that
blanket restriction for Kagi only.

## Tailscale Management

Tailscale is foundational. The user approved the following implementation direction:

- Keep the standalone macOS app, currently declared as `tailscale-app` via
  nix-darwin's Homebrew configuration, rather than changing network backends.
- Give Tailscale its own feature module that owns app installation and CLI
  integration. Use the standalone app's supported CLI integration or a deliberate
  wrapper targeting that installation, with the executable path verified.
- Do not add a second generic Nix Tailscale client/daemon and assume it controls
  the standalone app. Avoid conflicting CLI names and service ownership.
- Keep login, tailnet selection, and changes to network/DNS policy explicit.
  Do not embed an auth key or run disruptive network reconfiguration on every
  activation. Retain compatibility with the work device's MDM policies.

The pinned nix-darwin has `services.tailscale.enable`, but it installs the
CLI-only `tailscaled` distribution and a system launch daemon. It is not a
declarative wrapper around the existing GUI app. Upstream recommends the
standalone app for macOS and documents limitations of the CLI-only variant,
including no GUI, no MDM support, and incomplete exit-node-client support.

References:

- https://tailscale.com/kb/1065/macos-variants
- https://tailscale.com/kb/1080/cli
- https://github.com/nix-darwin/nix-darwin/blob/15abb8c98f336cd8bd840d71059adebabe60bf04/modules/services/tailscale.nix

## Removal Scope

Approved target-repository cleanup, to implement as a clearly identified change:

- Delete `modules/_disabled/syncthing.nix`.
- Delete `secrets/syncthing/cert.age` and `secrets/syncthing/key.age`, and their
  entries in `secrets/secrets.nix`. No decryption is needed for removal.
- Delete `modules/_disabled/README.md` if the directory is otherwise empty and
  has no remaining purpose.
- Delete the unreferenced `modules/terminal/zellij-config.kdl`.
- Remove Homerow and VS Code cask declarations and stale commented-out Talon and
  Tor Browser declarations from `modules/brew.nix`.
- Do not introduce retired WezTerm, Zellij, Sketchybar, Linux-builder, tmux
  persistence, Spotify, Talon, or xbar configurations from the legacy source.
- Do not import legacy jfrog-cli, Maven, CocoaPods, mpv, or Apple container
  declarations. None is currently declared in the target repo.
- Review references after deletion; retain historical migration/prototype records
  where mentions explain past behavior rather than keep a live dependency.

The current target has no WezTerm, Sketchybar, or Linux-builder implementation to
delete. Their old source files are in `~/.dotfiles`, which still configures the
current work laptop. Do not modify that separate repository or its existing local
changes as a side effect of target cleanup. Retirement of the source repository
is a separate operation.

Deleting configuration does not authorize deleting `~/syncthing` content,
application data, user-authored configs outside this repo, or the old machine's
keys. Do not use Brew `zap` as a bulk cleanup shortcut. Installed-app removal is
a separately reviewed activation/uninstall action, not part of this planning edit.

## First Implementation Boundary

Write a scoped implementation plan for explicit composition and host metadata
using these decisions. Keep the approved removal work in a separately identified
cleanup change; do not quietly fold it into a behavior-preserving refactor.
Do not expand the structural change into the secrets or OpenCode migration.

That structural implementation should:

1. Replace both host-level registry-wide imports with explicit named compositions.
2. Introduce one source of host/account facts and remove duplicated personal path
   assumptions from consumers without changing the existing personal values.
3. Preserve the personal output name, state versions, installed app/package sets,
   current enabled services, and generated behavior.
4. Keep reusable features separately selectable and register work additions without
   enabling them on personal. Container implementations must be exclusive: work
   must never inherit personal Podman packages or Docker-name wrappers, and neither
   profile may install MDM-owned Slack or work Docker Desktop.
5. Test selected features, identities, paths, and profile separation. If new work
   machine facts are not yet available, use clearly isolated evaluation fixtures,
   not an apparently deployable output with invented account facts.
6. Make no system switch, credential enrollment, secret rekey, OpenCode restart,
   dependency update, or unrelated worktree edit.

The target matrix describes the eventual arrangement. It does not authorize the
structural change to upgrade personal from its current generated OpenCode setup
to mutable OpenCode2, install missing fonts, change Git/jj semantics, or change
Brew cleanup behavior. Those are separate follow-on changes. Approved removals
must appear as their own intentional cleanup diff, with a fresh baseline afterward.

The rebuild helper currently targets a fixed checkout/host and uses a moving
nix-darwin reference. The structural plan should distinguish parameterizing its
inputs from repairing execution/failure behavior; both must be reviewed and tested
before any deployment, rather than claiming an entirely behavior-neutral refactor
while silently rewriting it.

## Remaining Review

1. Review ownership of shared agent instructions/custom definitions, cache trust,
   and any remaining work-policy differences before their respective changes.

Machine/account facts, work Git identity, and production recovery custody will be
collected explicitly before their respective implementation stages. They need
not block agreeing on feature placement.

## Evidence

- `modules/hosts.nix`: current import-all assembly.
- `modules/coreutils.nix`: general tools and the embedded seventeenlands package.
- `modules/fish.nix`: hardcoded profile, work helpers, rebuild target, shared shell behavior.
- `modules/vcs.nix`: profile-dependent identity and current Git/jj behavior.
- `modules/brew.nix`, `modules/ebooks.nix`: current personal application inventory.
- `modules/window-management.nix`, `modules/terminal.nix`: desktop/application routing and fonts.
- `modules/podman.nix`: Docker-name compatibility wrappers.
- `modules/nix.nix`, `modules/user.nix`, `modules/secretive.nix`: system/account policy and paths.
- `~/.dotfiles/hosts/aphrodite/brew.nix`: legacy work Brew inventory.
- `docs/plans/secure-enclave-secrets-prototype.md`: approved experiment and prior decisions.
- `../shiny-wolf/docs/plans/secure-enclave-secrets-prototype-results.md`: recorded successful live prototype; fresh-login test remains unverified.
- `../shiny-wolf/docs/plans/secure-enclave-secrets-production-handoff.md`: implementation findings and remaining production gates.

The two sibling-worktree paths are discovery references, not stable repository
dependencies. Consolidate that work deliberately before depending on its files.
