# New Mac First-Switch Bootstrap

## Purpose And Timing

Implement a user-facing bootstrap script that takes a new Apple Silicon work Mac
from a working Lix-installer Nix installation to its first successful nix-darwin
switch from this repository.

This is the final deployment feature, after profile composition, approved work
tooling, production age integration, and mutable OpenCode2 service ownership are
implemented and tested. It is not an extension of the structural refactor's
permission to modify the running laptop. Do not use Superpowers.

Design authority: `profile-boundaries.md`, `profile-composition-implementation.md`,
and the production secrets implementation/results that follow the successful
Secure Enclave prototype. Do not implement a parallel host, secret, or service
configuration inside the bootstrap script.

## Starting Point

The only guaranteed preinstalled third-party software is a working Nix
implementation installed with the Lix installer. Assume the user has the standard
macOS Terminal and system utilities, a logged-in GUI account, network access, and
the ability to approve administrator operations. These are operating conditions,
not additional preinstalled developer tools.

Do not assume any of these are present or configured:

- A repository checkout or usable Git; `/usr/bin/git` may only be an Xcode stub.
- Apple Command Line Tools, Xcode, or Homebrew.
- nix-darwin, Home Manager CLI, Fish, just, jq, Python, Node, or GitHub CLI.
- Secretive, SSH keys, GitHub authentication, or an existing age identity.
- Bitwarden, an unlocked vault, or a local recovery private key.
- AWS/Jira/OpenCode/Tailscale login sessions or App Store authentication.
- MDM application deployment having finished, even though MDM owns Docker Desktop
  and Slack on work.

The script obtains its non-system tools through the repository's locked Nix
inputs. It does not reinstall Nix, run an unrelated Nix installer, or replace Lix
with upstream Nix as a side effect. The selected system must keep Lix as its
configured Nix implementation.

## Deliverables

| File/output | Responsibility |
| --- | --- |
| `modules/bootstrap.nix` | Flake-parts package/app/check outputs; no automatic activation on import |
| `scripts/bootstrap.sh` | One small phase-oriented driver, executed with Nix-provided Bash and tools |
| `tests/bootstrap.sh` | Stubbed orchestration/safety tests; no real sudo, installers, keys, services, or switch |
| `docs/bootstrap.md` | First-run command, enrollment/resume procedure, manual prerequisites, troubleshooting and recovery |
| `apps.aarch64-darwin.bootstrap` | Nix entry point runnable without a checkout or developer tools |
| Bootstrap validation report | Observed new-Mac results and outstanding manual steps, without credentials |

Use the existing host/profile records and production secret/runtime helpers.
Expose only the small non-secret metadata subset the driver needs; do not dump
the full evaluated Darwin/Home Manager configuration.

## User Interface

Provide these modes through the same entry point:

| Mode | Behavior |
| --- | --- |
| `--help` | Explains prerequisites, effects, enrollment, and all options; no machine mutation |
| `--check --host NAME` | Inspects readiness and reports the plan/blockers without enrollment, installers, or activation |
| `--prepare-enrollment --host NAME --profile work` | After confirmation, prepares/reuses the device identity and emits public enrollment information; never switches |
| `--apply --host NAME` | Runs approved prerequisite preparation, verifies enrollment, builds, asks for final confirmation, and performs the first switch |

Permit `--checkout PATH` to choose the durable user-owned source location. Default
to a clearly documented location under the actual user's home, not a previous
agent's worktree. A bare invocation must not silently perform a switch.

The runbook's canonical invocation is through a full reviewed Git commit:

```sh
nix --extra-experimental-features 'nix-command flakes' run \
  "github:ajaxbits/macos-nix/${REV}#bootstrap" -- --check --host "$HOST"
```

`REV` and `HOST` above represent the chosen reviewed commit and exact configuration
output, not defaults inferred from the current machine name. The final runbook
must explain how the user obtains those values and show the corresponding prepare
and apply invocations. Do not give a moving `main` or `master` command as the
production default. The bootstrap output does not exist yet at spec-writing time.

This GitHub flake acquisition path must work without a local Git checkout or
Secretive key. For a public repo it must work anonymously. If repository/input
visibility requires authentication, document a supported HTTPS/Nix credential
setup or reviewed source-bundle alternative using only Lix and OS utilities.
Do not pretend private repository access is possible without authorization, put
tokens in URLs/command arguments, or depend on a tool that can only be fetched
after accessing the same private repo.

`--check` may fetch/build Nix tools and write non-secret local diagnostics. It
must not call sudo, generate a key, invoke an installer, rewrite a checkout, or
change services. Explain this distinction from a completely offline dry run.

## Phase 1: Preflight And Source Acquisition

Run the top-level script as the logged-in user, not root. Reject execution from
a root shell rather than guessing which account should own files. Validate:

- Native Apple Silicon execution, supported macOS, a functioning Lix daemon, and
  the selected packages' platform requirements. Detect unsupported Rosetta/mixed
  architecture execution rather than creating an Intel Homebrew installation.
- The active GUI user, actual home directory and UID, and ability to approve sudo.
- Connectivity to required source/cache endpoints without printing credentials.
- Whether an existing nix-darwin configuration or MDM-managed installation would
  make this a migration rather than a first bootstrap. Stop for explicit review
  rather than treating an existing setup as disposable.

If Nix is not on PATH after installation, give the Lix installer shell-initialization
instruction or resolve its documented installed location. Do not rewrite startup
files blindly. Supply flakes/nix-command flags per invocation if needed, without
making unrelated permanent configuration changes.

Obtain Bash, Git, jq, age, age-plugin-se, the plugin-aware agenix CLI, and the
appropriate pinned rebuild executable through Nix. Do not require Homebrew to
obtain the tools needed to install Homebrew. Do not invoke Apple's Git stub.

Use Nix-provided Git over HTTPS to create a durable checkout at the reviewed
revision, or materialize an equivalent reviewed source snapshot with an explicit
update workflow. Keep it user-owned. If the target directory exists, inspect and
reuse it only when its identity/revision/state matches; do not reset, clean,
overwrite, or silently update a dirty/unrelated checkout.

The package running the bootstrap, source checkout, lockfile, evaluated metadata,
and selected system build must refer to the same reviewed source revision. If a
new revision is needed for enrollment, re-run the bootstrap from that newly
reviewed revision explicitly; do not pull a moving branch mid-run.

## Phase 2: Validate Host Facts

Require the selected real output to match the actual username, home, UID/account
ownership, architecture, profile, and work Git identity. Keep output name distinct
from hostname. Do not rename an MDM-managed machine or create/reassign an account
to satisfy a mismatched host record.

If the host does not yet exist in the reviewed source, enrollment preparation may
emit a non-secret candidate host record for review. It may not invent a deployable
host, rewrite tracked Nix files and switch them immediately, or fall back to
`Alexs-MacBook-Air`. Final `--apply` requires a reviewed real host definition.

Validate that work does not install personal Podman/Docker wrappers, Bitwarden,
retired tools, MDM Docker Desktop, or MDM Slack. Require non-destructive Brew
cleanup and no bulk upgrades for the first work switch. Explicitly verify the
selected output retains Lix and does not require the old personal bitwarden key.

List proposed cache/trusted-key changes and require informed approval for new
trust. Initial tool acquisition must not depend on accepting the personal cache.
Do not pass `--accept-flake-config` blindly across the whole workflow.

## Phase 3: Prepare Platform Prerequisites

Inventory prerequisites before installing anything and obtain confirmation for
the specific changes. Reuse a healthy native Homebrew installation rather than
reinstalling it, changing its owner, or deleting an alternate installation.

For missing Command Line Tools, use the supported Apple installation mechanism.
If it opens a GUI, requires Apple/MDM approval, or cannot finish within a bounded
wait, stop with a resumable instruction. Do not accept licenses on the user's
behalf, install full Xcode unnecessarily, or run broad `softwareupdate --all`.

Install Homebrew into its supported native prefix using a reviewed upstream
installer payload pinned by revision/hash or a verified release. Do not execute
a mutable download directly through `curl | bash`. Run Homebrew as the user;
only its explicitly required privileged operations use sudo. Make its absolute
path available to activation without relying on a new Fish session.

Pinning an installer is not a claim that Homebrew cask versions are locked by
`flake.lock`. Document the remaining Homebrew/app update behavior honestly.

Validate all requirements for the selected app installation methods before the
final switch. Drafts may require App Store sign-in/availability depending on the
chosen implementation. Provide a manual login/resume step, never collect Apple
account passwords, and do not report a complete bootstrap if a required app
installation is knowingly blocked. If any optional component is deliberately
deferred, document it explicitly instead of silently dropping it from the profile.

MDM-owned Docker Desktop and Slack are detected/reported, never installed by this
script. Pending MDM delivery is a separately reported readiness item; do not
substitute Podman or another Slack installer. Do not launch Docker or modify
Docker contexts merely to check that an application exists.

## Phase 4: Device Enrollment And Secret Readiness

Use the production age identity path from the selected host configuration, outside
Git/Nix in a durable private user-owned directory. Reuse an existing validated
identity; never regenerate or overwrite it on rerun. Generate a new device-bound
identity with `--access-control=none` only after explicit approval, with private
directory/file permissions and the plugin's output directed to a file.

A fresh identity cannot decrypt existing ciphertext until its recipient is added.
The supported enrollment workflow is:

1. The new Mac prepares its identity and exports only the public recipient plus
   non-secret host/account metadata.
2. An authorized existing device or recovery custodian adds the recipient to the
   appropriate rules and re-encrypts the existing secrets.
3. The reviewed host definition/rules/ciphertext are made available in a new
   explicit source revision or equivalently reviewed release artifact.
4. The user resumes bootstrap from that revision, retaining the same identity.

The script must explain this pause rather than attempt to reconstruct credentials,
copy a recovery private key onto the laptop, generate empty placeholder tokens,
or disable secrets so the switch appears successful. Public enrollment information
is safe to transfer; private identity material must not be uploaded or printed.

Kagi uses the approved shared ciphertext audience, including both enrolled Macs.
GitHub/Terraform/Jira work secrets remain restricted to their intended recipients.
OPENAI_API_KEY is absent. Recovery custody is a prerequisite production decision,
not solved by creating a backup identity next to the primary during bootstrap.

Before switching, perform a non-disclosing readiness check using the production
plugin-aware age implementation and only the intended primary identity. Verify all
required secrets can be decrypted; do not silently succeed via unrelated default
SSH identities. Avoid writing plaintext merely for this check where possible. If
temporary plaintext is necessary, restrict and clean it up without logging it or
claiming secure erasure. Do not compare real token contents to a stored baseline.

Enrollment requiring another authorized device is not an extra installed-software
dependency on the new Mac. It is an unavoidable authorization step for existing
encrypted data and must be described plainly in the runbook.

## Phase 5: Build And Review

Build the exact selected system as the normal user using the immutable reviewed
source and its lockfile. No input update, lockfile rewrite, impure home-directory
import, or unreviewed generated configuration is permitted. Retain a GC root for
the build until activation completes or the run is deliberately abandoned.

Capture the built system path and a narrow activation summary: selected host/user,
profile, source revision, package/app additions, account/defaults/launch-agent
changes, Nix/Lix policy, Brew policy, and secret names/paths without values.

Check initial nix-darwin and Home Manager file collisions. Do not automatically
delete `/etc` files, override foreign symlinks, use `force` on user configuration,
or overwrite an existing backup. If a reviewed individual backup is necessary,
use a unique backup name, record it, and obtain approval. Existing OpenCode
JSON/JSONC, CLI settings, plugins and runtime state remain user-owned.

Present the final summary and require an affirmative confirmation before the
first switch. Installing prerequisites or preparing enrollment is not consent
to activate the system. A failed build or readiness check must never reach this
confirmation or invoke the switch.

## Phase 6: Perform The First Switch

Obtain sudo credentials through normal terminal interaction. Never store the
password, read it into a shell variable, or forward the user's full environment
with `sudo -E`. Use explicit executable paths so sudo's PATH cannot select the
wrong Nix or rebuild tool.

Invoke the repository-pinned nix-darwin rebuild implementation with `switch`, the
same immutable source and explicit host selector, and flags prohibiting lockfile
changes. Do not use `nix-darwin/master`, infer the output from the machine name,
or switch a mutable checkout that changed after review. Ensure root-side
evaluation needs no new private-source credentials by realizing required inputs
and the system beforehand; stop rather than requesting broad credential export.

Verify the actual pinned rebuild CLI instead of inventing an apply-prebuilt flag.
At the inspected revision, `switch` builds/selects the system profile and then
activates it; `activate` alone is not an equivalent first-switch operation. If
`switch` reevaluates the source, its immutable input must resolve to the system
path already reviewed and built. Do not reproduce nix-darwin's activation logic
as a bespoke sequence of arbitrary privileged scripts.

The activated production coordinator must be the sole owner of secret-dependent
OpenCode startup. Secrets are decrypted in the intended user's GUI context, not
by attempting to use that user's Secure Enclave identity from a root bootstrap
process. Avoid duplicate starters and silent startup without required credentials.

Bootstrap execution must not require Secretive authentication to finish fetching
the very configuration that installs Secretive. SSH key enrollment can follow
installation independently; keep the source-acquisition path usable over HTTPS.

## Phase 7: Verify And Report

Verify the selected system/profile path matches the reviewed build, Lix remains
the installed Nix implementation, expected commands are available, and user
ownership/home paths are correct. Check actual service health with bounded waits,
not merely that plist installation or `service start` returned successfully.

Verify secrets exist with intended ownership/permissions without displaying them.
Verify OpenCode2 starts through the managed coordinator, uses the expected Nix
executable, and has writable application configuration. Do not send a paid model
request just to prove the executable starts.

Check Tailscale CLI availability for the standalone app. Do not authenticate it,
join a tailnet, enable routes, change DNS, or replace it with `tailscaled` without
a distinct approved action. Report required extension/VPN approval separately.

Report bootstrap status in distinct categories:

- System switched and core verification passed.
- Required configuration or service checks failed/incomplete.
- Manual onboarding outstanding: App Store, Secretive enrollment, macOS privacy
  permissions, provider/MCP OAuth, AWS/Jira/GitHub authentication, MDM delivery,
  Tailscale enrollment, as applicable.
- Fresh-login/reboot validation outstanding or passed.

Do not mark required failed checks as success because the switch command exited
zero. Do not claim fresh-login behavior was verified by bootstrapping into the
current GUI session. Any logout/reboot is user-initiated and separately approved.

## Resume And Failure Semantics

Use a small user-owned checkpoint record outside the source tree containing only
revision, selected host, phase/status, paths, public enrollment metadata, and
recorded backups. Never put credentials or sudo passwords in it. Validate actual
machine state on rerun rather than trusting a stale success flag. Prevent concurrent
bootstrap runs for the same user/target with a bounded, recoverable lock.

Distinguish waiting for enrollment, waiting for user/platform action, ordinary
failure, and verified completion in the CLI output/exit behavior. Reruns must not
regenerate keys, repeat installs unnecessarily, duplicate shell configuration,
overwrite OpenCode files, reset a checkout, or rejoin a tailnet.

A failed activation may have partially changed macOS, Brew, or user configuration.
Do not describe it as transactional or automatically undo unrelated changes. Keep
the built output, phase log, and specific backup paths available for recovery.
If a previous Darwin generation exists, offer the pinned tool's rollback procedure
with its limitations. On a genuinely first switch there may be no prior generation;
do not assume `--rollback` can restore the Lix-only starting state. Do not uninstall
Lix or delete `/nix` as an automatic recovery action.

Logs must be private and redacted. No shell tracing, environment dumps, token URLs,
identity contents, or decrypted values. Cleanup is scoped to bootstrap-owned
temporary files; persistent enrolled identities are never deleted by generic cleanup.

## Acceptance Tests

Implement software-only tests with stub executables and temporary directories:

| Scenario | Required behavior |
| --- | --- |
| Lix-only minimal PATH | No dependency on Git, Brew, Fish, jq, just, or darwin-rebuild already installed |
| Missing CLT/Brew | Specific approved setup/resume path, no full Xcode or unrelated software updates |
| Public source acquisition | No SSH/Secretive/GitHub login dependency |
| Private source unavailable | Actionable authentication/source-bundle blocker, no credential leakage |
| Unknown/mismatched host | No fallback hostname, account mutation, or activation |
| Existing dirty checkout | Preserve it and stop or use a separately approved destination |
| Source revision changes | Re-review/rebuild required; no stale-plan activation |
| Fresh device identity | Explicit enrollment pause; same identity reused on resume |
| Missing/wrong recipient | No switch or secret-dependent service startup |
| Failed build | No sudo switch call |
| Final confirmation declined | No activation |
| MDM Docker/Slack absent | Report pending delivery; never install substitutes |
| Work profile | No personal Podman wrappers, Bitwarden, or retired tools |
| Existing OpenCode state | Files/dependencies preserved and writable |
| Interrupted/rerun bootstrap | No overwritten identities, duplicate installs/agents, or broad cleanup |
| Switch fails midway | Honest partial-state report and scoped recovery guidance |
| First-generation recovery | No nonexistent rollback assumption or automatic Nix uninstall |
| Verification failures | Incomplete/failure status, not a misleading successful bootstrap |

Then validate on the actual new Mac, starting with the Lix-only assumptions,
after explicit user approval. Software stubs cannot establish installer behavior,
Secure Enclave access, MDM interactions, or real activation success. Record which
conditions were actually exercised; do not present a test on an already-configured
laptop as proof of a Lix-only first installation.

## Documentation And Handoff

The finished runbook must include the exact supported invocation, how to obtain
the reviewed revision/host selector, prerequisite prompts, enrollment exchange,
resume procedure, typical blockers, and the resulting everyday rebuild command.
It must explicitly state that neither the old laptop's configuration nor its
credentials are modified by running bootstrap on the new Mac.

The implementation agent may write/build/test the script without activating any
machine. Adding this specification is not approval to run installers, create real
identities, or perform the first switch on the current laptop. Those actions occur
only when the user deliberately runs and confirms the bootstrap on the target.

## References

- Lix installation and compatibility: https://lix.systems/install/
- Pinned nix-darwin first-install instructions: https://github.com/nix-darwin/nix-darwin/blob/15abb8c98f336cd8bd840d71059adebabe60bf04/README.md
- Pinned rebuild CLI behavior: https://github.com/nix-darwin/nix-darwin/blob/15abb8c98f336cd8bd840d71059adebabe60bf04/pkgs/nix-tools/darwin-rebuild.sh
- Homebrew installation requirements: https://docs.brew.sh/Installation
- Secure Enclave identity behavior: https://github.com/remko/age-plugin-se
- macOS Tailscale variants: https://tailscale.com/kb/1065/macos-variants
