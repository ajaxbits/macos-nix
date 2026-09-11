# New Mac Bootstrap Implementation Results

## Implemented

The flake now exposes `apps.aarch64-darwin.bootstrap` and
`packages.aarch64-darwin.bootstrap`. The guided script supports:

- `--check`: read-only machine and host readiness.
- `--prepare-enrollment`: confirmed unattended Secure Enclave key generation and
  public-recipient enrollment instructions.
- `--apply`: exact-revision checkout, secret readiness, platform prerequisites,
  build, privileged activation check, final confirmation, switch and verification.

The packaged application supplies Bash, Git, jq, Lix, plugin-aware agenix,
age-plugin-se, the guarded key generator, and the pinned nix-darwin rebuild tool.
It does not require those commands, Homebrew, Fish, just, Home Manager, or
nix-darwin to be preinstalled.

The Homebrew installer script is fetched at commit
`8949852f785a3bacaba2a979d0790337950b0a4a` with hash
`sha256-JVSOHaeTDBVj274ssFg0pBMcTaCSNFQLb9rIEv2jwoc=`. The script first obtains
sudo credentials interactively and runs the installer with a minimal environment.
Homebrew itself and casks remain moving Homebrew-managed software.

## Safety Properties

- Bare invocation never mutates the machine.
- Unknown/mismatched hosts, account facts, console user, home, UID, architecture,
  dirty checkout, changed revision and non-immutable source revisions stop safely.
- The real work host must exist in reviewed metadata; none is invented.
- Existing nix-darwin requires explicit migration opt-in.
- Alternate/invalid Homebrew installations are not overwritten.
- Existing age identities must be regular, private, user-owned files beneath a
  private user-owned directory.
- Required ciphertext is derived from all evaluated Home Manager age declarations,
  not a fixed list in the shell script.
- Secret-readiness plaintext uses a private temporary directory with exit/signal
  cleanup and is never logged.
- Build, privileged activation check and switch use the same immutable GitHub
  revision. The durable checkout is revalidated before privilege escalation.
- Work hosts use no automatic Home Manager backup suffix; collisions fail the
  activation check for explicit review.
- Build/check/switch/verification failures record distinct checkpoint phases.
- Completion requires the active nix-darwin profile to resolve to the reviewed
  build and the switched Nix implementation to remain Lix.
- Packaged execution clears test command overrides from the caller environment.

## Software Verification

The test suite uses only stubs and temporary files. It covers:

- Lix-only command sourcing and read-only checks.
- Explicit enrollment, immutable revision enforcement and private checkpoints.
- Existing identity permissions and active console-account validation.
- Existing nix-darwin rejection without explicit migration review.
- Dirty/mismatched checkouts and wrong secret recipient failure.
- Missing Command Line Tools pause/resume.
- Alternate Homebrew rejection and pinned installer execution after `sudo -v`.
- Failed build preventing sudo.
- Activation-check and switch failure checkpointing.
- Active profile mismatch after switch.
- Final confirmation decline and successful exact-host switch.

Verified commands:

```sh
nix build --option eval-cache false --no-write-lock-file --no-link \
  'path:.#checks.aarch64-darwin.bootstrap'
nix build --no-write-lock-file --no-link 'path:.#bootstrap'
nix flake check --no-write-lock-file 'path:.'
```

No real identity, decrypted secret, installer, sudo operation, activation, network
configuration, checkout clone, or system switch was performed by these tests.

## External Gate

The repository currently has no real work host output. Before live use, add and
review the new Mac's output name, hostname, username, home, UID/account policy,
work Git identity, `secure-enclave` identity path, non-destructive Homebrew policy,
and complete work profile. Publish that commit, then run bootstrap by its full
40-character revision as documented in `docs/bootstrap.md`.

The first live run remains an explicitly confirmed operation. Software simulation
does not prove MDM timing, Apple installer behavior, actual Secure Enclave access,
Homebrew installation, or nix-darwin activation on the new laptop.
