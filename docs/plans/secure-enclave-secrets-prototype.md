# Unattended Secure Enclave Secrets Prototype

## Objective

Prove that this repository's pinned agenix can decrypt a disposable secret using
`age-plugin-se` without biometric or passcode approval, both from a terminal and
from a logged-in user's launch agent. Prove that a dependent process runs only
after successful decryption, and demonstrate recovery using a separate recipient.

This is an isolated feasibility experiment, not the production secrets migration.
Do not use Superpowers skills or workflows when executing this plan.

## Confirmed Decisions

- Keep the existing dendritic/flake-parts architecture. Later profile work will
  use explicit foundation, personal, and work compositions.
- Both personal and work will use Nix-managed OpenCode2 with user/application-owned,
  writable configuration. Do not implement that migration in this prototype.
- Prototype agenix plus `age-plugin-se` before considering sops-nix.
- Use `age-plugin-se` access control `none`: unattended use of a device-bound key.
- Keep Secretive for SSH as a separate concern. Do not attempt to reuse or export
  a Secretive key for age decryption.
- Production secrets to consider later: `KAGI_API_KEY`, `GITHUB_TOKEN`,
  `TF_TOKEN_app_terraform_io`, and `JIRA_API_TOKEN`. Exclude `OPENAI_API_KEY`.
- Work and personal recipients and secret selections must remain separate in the
  eventual production design. Neither recipient set is being created here.

## Security Model

Apple Secure Enclave is the hardware involved, not a conventional TPM.
`age-plugin-se` persists a protected, device-bound identity representation in a
file. This is not an ordinary portable plaintext private key, but it is still
private material: keep it outside Git and the Nix store and restrict access.

With access control `none`, sufficient access on this Mac permits key use without
user approval. Hardware binding protects against off-device use of a copied
identity; it does not prevent local malware from requesting decryption or reading
already-decrypted tokens. Decrypted files and consumer process memory remain
plaintext. Do not claim that a macOS temporary directory is RAM-backed, wiped on
screen lock, or guaranteed to disappear on logout/reboot.

The recovery identity in this experiment is a disposable software age key. It is
only a test fixture, not a decision to store a production recovery key on the same
Mac as its hardware-bound identity.

## Repository Context

The current workspace is `/Users/alexander.jackson/code/proud-garden`, a worktree
of `ajaxbits/macos-nix`. Another checkout may be used by the implementing agent;
derive the repository path instead of embedding this absolute path in scripts.

Relevant files:

| File | Current behavior |
| --- | --- |
| `flake.nix` | Imports `./modules` through import-tree; pins agenix, Home Manager, and nixpkgs |
| `modules/hosts.nix` | Imports all values of both `flake.modules.darwin` and `flake.modules.homeManager` into the personal host |
| `modules/secrets.nix` | Uses agenix Home Manager, a personal `/Users/ajax/.ssh/bitwarden` identity, and the real Kagi ciphertext |
| `secrets/secrets.nix` | Production recipient rules; do not change or use for this experiment |
| `justfile` | Existing production secret commands use an unpinned agenix reference and personal identity; do not invoke them for this experiment |

The current checkout was clean at plan creation. There are existing unrelated
changes in `~/.dotfiles` and the sibling `~/code/macos-nix` worktree, including
OpenCode changes. Do not modify, stage, or revert them.

At inspection, the root inputs resolved to:

| Input | Revision |
| --- | --- |
| agenix | `b027ee29d959fda4b60b57566d64c98a202e0feb` |
| Home Manager | `83b7606dcf44abe3a94b86e8bb2b3355d22e8797` |
| nixpkgs | `0e251e24a4f24e036a084b6b4b2d2491af4167f4` |

Resolve pins through `flake.lock`'s root input map when checking these values;
the root Home Manager and nixpkgs nodes have suffixed names. The pinned nixpkgs
contains `age-plugin-se` version `0.2.1`. Recheck the actual checkout rather than
assuming its lockfile still matches these revisions.

The pinned agenix Home Manager module creates a mounting script and exposes it
through `config.launchd.agents.activate-agenix.config.ProgramArguments`. It runs
age once per configured secret. Its default Darwin paths contain a shell
expression based on `getconf DARWIN_USER_TEMP_DIR`.

## Scope And Guardrails

- Use only generated dummy plaintext, fresh disposable identities, and experiment
  ciphertext. Never read, decrypt, rekey, or copy existing user secrets.
- Do not run `darwin-rebuild switch`, `home-manager switch`, any generated full
  Home Manager activation script, or the existing `nixre` helper.
- Do not change the user's shell, Nix installation, Homebrew state, real launch
  agents, OpenCode service, Secretive, login items, or production secret paths.
- Do not create a new `flake.modules.darwin.*` or `flake.modules.homeManager.*`
  registration for this prototype: the existing host would import it automatically.
- Do not use Superpowers, broad dependency updates, unpinned `nix run github:...`
  commands, or Homebrew installation as a silent fallback.
- Do not put private identities in Nix path literals, derivation inputs, generated
  store files, command arguments containing their contents, or logs. Runtime
  identity path strings are acceptable. Experiment ciphertext may enter the store.
- Do not run commands with shell tracing or dump the process environment.
- Obtain explicit approval before generating the disposable Secure Enclave
  identity and before registering a temporary launch agent. Explain the scoped
  changes together so the user can approve one live-test session.
- Never log the user out, reboot, or lock their screen automatically. Actual
  session-boundary testing is a separately approved manual step.
- Do not commit or push unless requested. Preserve unrelated changes.

## Deliverables

Keep the implementation small. Suggested files and responsibilities:

| File | Responsibility |
| --- | --- |
| `modules/secure-enclave-prototype.nix` | Flake-parts module exposing only prototype packages and software-only checks under `perSystem`; no host/module-registry activation |
| `prototypes/secure-enclave/prototype.sh` | Explicit experiment driver for fixture creation, CLI testing, scoped launch-agent testing, and cleanup |
| `prototypes/secure-enclave/agenix-runtime.nix` | Isolated evaluation fixture using the pinned Home Manager and agenix modules; never imported into an actual host |
| `prototypes/secure-enclave/test.sh` | Software-only tests for path safety, failure handling, ordering, and cleanup using stubs/dummy data |
| `docs/plans/secure-enclave-secrets-prototype-results.md` | Reproduction commands, observed results, limitations, cleanup status, and production recommendation |

The raw Home Manager evaluation fixture deliberately lives outside the
auto-discovered `modules/` tree. The one new file inside that tree must remain a
flake-parts module and must not enable anything on a host.

Expose `packages.aarch64-darwin.secure-enclave-prototype` so the driver can be
built with `nix build --no-write-lock-file .#secure-enclave-prototype`.
Provide a `--help` entry point describing the exact implemented subcommands and
which ones create keys or register agents. It must not start live tests implicitly.

## Execution Plan

### 1. Check Preconditions And Capture The Baseline

Inspect repository instructions, worktree status, root input pins, macOS version,
and hardware compatibility. `age-plugin-se` requires macOS 14 or later and Secure
Enclave hardware for key generation/decryption. Do not read existing key files.

Capture the current personal host's system derivation path:

```sh
nix eval --no-write-lock-file --raw '.#darwinConfigurations.Alexs-MacBook-Air.system.drvPath'
```

Also capture the evaluated host/user identity, package selections, Brew inventory,
enabled launch agents, secret declarations (paths/metadata only), and generated
shell/OpenCode configuration content for comparison. Source-root changes can alter
store paths and derivation hashes without changing intended host behavior.

Build the necessary tools from the existing pinned inputs. Package availability
or a successful build is not proof of hardware operation. If the plugin fails to
build or macOS refuses execution, record the exact issue and propose the smallest
targeted remedy. Do not disable Gatekeeper or update the whole lockfile.

### 2. Implement An Isolated Driver And Software Tests

Use a unique experiment directory outside the repository, created under the
platform-approved temporary location. Set `umask 077`, protect the directory with
mode `0700`, and protect identity files with mode `0600`. Use a sentinel identifying
the experiment directory and refuse cleanup of arbitrary or production paths.

Separate read-only preflight/help from live operations. A rerun must not overwrite
an existing identity, register duplicate agents, or silently reuse another run's
fixtures. No secrets or identity contents should appear in command output.

Build a plugin-aware age executable with an explicit PATH containing the pinned
`age-plugin-se`. Use that same age implementation for the agenix CLI and the
isolated agenix Home Manager runtime. A Fish PATH modification alone is inadequate.
The agenix CLI's `ageBin` override and the Home Manager module's `age.package`
provide the relevant integration points at the inspected revision.

Test software behavior before live key creation. Use stubs to prove that a failed
decryptor never invokes the dummy consumer, cleanup stays within the experiment,
and rerunning does not overwrite fixtures. Hardware tests must not run as flake
checks, inside a Nix build sandbox, or on CI automatically.

### 3. Prove Hardware Roundtrip And Agenix CLI Compatibility

After approval, generate the primary test identity using the pinned plugin:

```sh
age-plugin-se keygen --access-control=none -o "$identity_path"
```

The driver must set `identity_path` to a fresh private path inside its experiment
directory. Always supply `-o`; never allow identity material to go to stdout.
Capture the public recipient separately without displaying the private identity.

Create a fresh software age recovery identity and unrelated wrong-key identity in
the same restricted experiment directory. Encrypt known dummy data to both the
Secure Enclave recipient and the recovery recipient. Use a private, experiment-only
agenix rules file with exactly those recipients, not `secrets/secrets.nix`.

Verify the dummy data roundtrips through the pinned agenix CLI with only the
Secure Enclave identity supplied. Confirm that no Touch ID or passcode prompt is
required. Run a second decryption to confirm repeatability. Distinguish any macOS
first-execution trust prompt from authentication required by the key policy.

Exercise agenix editing/re-encryption or rekeying on the dummy ciphertext using
its own rules and explicit identity. Verify content equality without printing
identity material. Do not use the production justfile recipes.

### 4. Exercise The Actual Pinned Agenix Runtime

Evaluate a standalone Home Manager fixture with only the required Home Manager
settings and the pinned agenix module. Supply a scratch home and explicit paths
for the experiment identity, ciphertext, `age.secretsDir`, and
`age.secretsMountPoint`. The identity must be a runtime string, not a Nix source
path. Only the disposable ciphertext should become a derivation input.

Set `age.identityPaths` to exactly the Secure Enclave test identity. Do not add
the recovery key or default SSH identities: successful primary tests must prove
hardware decryption, not a software fallback.

Build and extract the generated agenix mounting executable. Do not invoke full
Home Manager activation. Run that exact executable first from the terminal with
a minimal explicit environment, and verify the decrypted file's ownership,
permissions, content, and symlink/generation paths.

Use explicit experiment directories for isolation. Separately evaluate and record
the pinned module's default Darwin path behavior, so the result does not imply
that literal shell-expression paths work in JSON or direct launchd arguments.

### 5. Test Launchd And Dependent-Process Ordering

Use a uniquely suffixed label under `dev.ajaxbits.secrets-prototype` and a plist
inside the experiment directory. Register it only in the current user's GUI
domain (`gui/<uid>`), without sudo. Do not copy it to the user's permanent
`~/Library/LaunchAgents` directory for the ordinary test.

The prototype agent must have explicit executable paths, HOME, PATH, logs, and
experiment paths. Use `RunAtLoad = true` and no automatic retry loop. Its
coordinator runs the actual agenix mounting executable, checks success and the
required decrypted file, and only then invokes a dummy consumer.

The dummy consumer compares the fixture content and writes a success marker;
it does not print credentials, contact a network service, or start OpenCode.
This proves one coordinator's fail-closed sequencing, not automatic ordering
between unrelated production launch agents.

Verify with a bounded timeout that the agent completes unattended and the marker
exists. Record label, exit status, and relevant redacted logs. Do not leave a
stalled agent or plugin process running indefinitely.

Repeat with missing identity and invalid ciphertext, using fresh output directories
and markers. Expect a nonzero failure and no consumer marker. This prevents an old
decrypted fixture from masking a failed startup.

### 6. Test Rotation, Recovery, And Session Boundaries

Replace the dummy secret with a second known value through the experiment's agenix
rules. Re-run the coordinator and verify a newly invoked consumer sees the second
value. Document that an already-running consumer holding an old environment value
does not become updated automatically; production OpenCode restart remains separate.

Recover the ciphertext using only the disposable recovery identity, with no plugin
on PATH and no primary identity supplied. A software recovery pass proves the
second recipient works, not portability of the Secure Enclave identity. Test the
unrelated wrong key as well and require decryption failure.

Bootstrap into an existing GUI session verifies the launchd execution context, not
a real reboot/login transition. Offer a separately approved manual logout/login
or reboot test only after all earlier checks pass. It may require temporarily
installing the uniquely named prototype plist as a login agent and using a private
experiment location that survives the transition. Obtain approval for that added
persistence and remove it afterward. Never automatically trigger the transition.

If the user does not perform that test, mark cold-login behavior as unverified and
carry it forward as a gate before production rollout. Do not claim cross-device
failure was experimentally established unless a second compatible Mac was tested.

### 7. Clean Up And Report

Unload only the exact prototype label recorded for this run. Remove any approved
temporary login-agent installation, stop owned remaining test processes, and
remove the experiment directory after collecting non-sensitive results. Cleanup
must be repeatable and must not enumerate/unload unrelated agents.

Check the plugin version's identity lifecycle before claiming that deleting a file
removes every hardware-related artifact. Record any residual artifact or manual
cleanup requirement. Normal filesystem deletion is not a secure-erasure guarantee.

Run software checks and the baseline personal-host evaluation again. Compare the
recorded evaluated settings and generated configuration content, accounting for
source-root/store-path changes. Investigate derivation differences, but do not
treat a different hash alone as a behavioral regression. The prototype must not
change the personal host's selected features or effective settings. Confirm no
production configuration files or lockfile were changed.

Write the results document with tool/input versions, macOS/hardware details needed
for reproduction, exact commands used, outcomes below, limitations, cleanup status,
and a recommendation. Exclude identities, credentials, full environment dumps, and
unnecessary machine identifiers. Clearly separate source-supported expectations
from observed hardware behavior.

## Acceptance Matrix

| Check | Required result |
| --- | --- |
| Pinned tools build | Successful build without broad dependency changes |
| Software-only checks | Pass without touching hardware or launchd |
| Secure Enclave primary decrypt | Correct dummy plaintext, no authentication prompt, no recovery fallback |
| Repeated primary decrypt | Same result without user interaction |
| Agenix CLI edit/rekey | Works using experiment rules and plugin-aware age |
| Pinned agenix runtime | Successfully writes restricted files inside the experiment |
| GUI launch-agent decrypt | Same success with an explicit minimal environment |
| Missing identity / invalid ciphertext | Visible failure, no consumer success marker |
| Rotation | New consumer receives updated dummy data |
| Recovery-only decrypt | Success without the Secure Enclave identity or plugin |
| Wrong-key decrypt | Failure |
| Actual fresh login/reboot | Pass if separately approved; otherwise explicitly unverified |
| Cleanup | Prototype agent unloaded, experiment material removed, residuals documented |
| Personal host baseline | Unchanged effective configuration; no production service or secret changes |

## Follow-On Decision

If the prototype passes, the next plan can implement production runtime secret
loading and then integrate it with the agreed profile composition and OpenCode2
ownership model. That follow-on must decide recovery-key custody, plaintext
retention, production recipient enrollment, rotation/restart behavior, and actual
cold-login sequencing before any real credentials are migrated.

If the prototype fails, report the narrow failure layer: plugin packaging, hardware
access, age/agenix integration, GUI session execution, or sequencing. Do not switch
to sops-nix merely to hide a Secure Enclave or login-context failure; it may use the
same plugin and encounter the same constraint.

## References

- Secure Enclave plugin: https://github.com/remko/age-plugin-se
- Pinned agenix Home Manager runtime: https://github.com/ryantm/agenix/blob/b027ee29d959fda4b60b57566d64c98a202e0feb/modules/age-home.nix
- Pinned agenix CLI: https://github.com/ryantm/agenix/blob/b027ee29d959fda4b60b57566d64c98a202e0feb/pkgs/agenix.sh
- Pinned agenix packaging/ageBin override: https://github.com/ryantm/agenix/blob/b027ee29d959fda4b60b57566d64c98a202e0feb/pkgs/agenix.nix
- Dendritic registration versus selection: https://dendrix.denful.dev/Dendritic.html
- Dendrix layers: https://dendrix.denful.dev/Dendrix-Layers.html
