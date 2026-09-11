# Bootstrap A New Work Mac

The bootstrap starts with one dependency: a working Nix installation from the
[Lix installer](https://lix.systems/install/). Run it from the standard macOS
Terminal as your normal logged-in account, not from a root shell.

Bootstrap is intentionally guided and resumable. It will explain every mutation
and ask before generating a Secure Enclave identity, opening Apple's Command Line
Tools installer, installing Homebrew, or switching the
system. `--check` is read-only apart from normal Nix fetching/build caching.

## Before Starting

Rsync the repository directory onto the new Mac, then enter it. The work host is:

- `HOST=K1H96QD74C`
- user `alexander.jackson`, UID `502`, home `/Users/alexander.jackson`

The host is registered for readiness checks, key enrollment, and the initial
foundation switch. Bootstrap never falls back to the personal output.

Nix may ask whether to trust this flake's extra substituters and public keys:

- `https://cache.nix.ajax.casa/patroclus` (personal cache)
- `https://cache.garnix.io`
- `https://cache.numtide.com`

The bootstrap does not require the personal cache. Declining the flake settings is
supported; Nix can use its normal configured caches or build locally. Only accept
additional cache trust after reviewing the URL and key shown by Nix.

## 1. Check Readiness

```sh
cd /path/to/rsynced/macos-nix
export HOST=K1H96QD74C
nix --extra-experimental-features 'nix-command flakes' run 'path:.#bootstrap' -- \
  --check --host "$HOST" --checkout "$PWD"
```

This checks the logged-in user, UID, home directory, Apple Silicon architecture,
LocalHostName, Lix, Command Line Tools, Homebrew, and configured age identity. It
does not use sudo, create a key, or activate nix-darwin.

If the host record does not match the new laptop, update and review the host record
instead of renaming an MDM-managed machine or letting bootstrap guess.

## 2. Generate The Device Identity

```sh
nix --extra-experimental-features 'nix-command flakes' run 'path:.#bootstrap' -- \
  --prepare-enrollment --host "$HOST" --profile work --checkout "$PWD"
```

After confirmation, this creates an unattended Secure Enclave identity at the
host's configured private path. It uses `--access-control=none`, never overwrites
an identity, and prints only the public `age1se...` recipient.

On an already authorized device or through the recovery custodian:

1. Add the public recipient to the shared Kagi rule and intended work-secret rules.
2. Rekey the ciphertext with an already authorized identity.
3. Review the host/rule/ciphertext changes.
4. Rsync the updated repository directory back to the new Mac.

Keep the private identity on the new Mac. Do not send it to the authorized device
or copy a recovery private key onto the laptop.

## 3. Resume And Apply

Enter the updated rsynced directory and run:

```sh
nix --extra-experimental-features 'nix-command flakes' run 'path:.#bootstrap' -- \
  --apply --host "$HOST" --checkout "$PWD"
```

Bootstrap then:

1. Reuses the existing Secure Enclave identity.
2. Validates the supplied rsynced source directory.
3. Proves this device can decrypt every required ciphertext without printing it.
4. Opens Apple's Command Line Tools installer if needed, then asks you to rerun.
5. Installs Homebrew from the repository-pinned official installer if needed.
6. Archives one immutable Nix store snapshot of the directory, then checks/builds it.
7. Runs a privileged activation/collision check against that same snapshot.
8. Shows the host/profile/source/system summary.
9. Requires a final `yes` before switching that same immutable snapshot.
10. Verifies nix-darwin is installed and the switched system still uses Lix.

Use `--checkout /absolute/path` if the rsynced directory is not the current
directory. Bootstrap does not modify or clean source files.

If nix-darwin is already installed, `--apply` stops because this is no longer an
ordinary first switch. After reviewing the existing installation, explicitly add
`--allow-existing-darwin` to proceed as a migration.

The Homebrew installer script is pinned and hash-verified by Nix. The Homebrew
release and casks it installs remain Homebrew-managed moving software rather than
being pinned by `flake.lock`. Bootstrap clears caller-provided source mirrors and
askpass settings from the installer environment and obtains sudo credentials
interactively before invoking its noninteractive phase.

## Manual Follow-Up

The switch does not authenticate applications or approve macOS privacy/network
extensions. Complete applicable steps afterward:

- Wait for MDM-owned Docker Desktop and Slack instead of installing substitutes.
- Enroll Secretive SSH keys.
- Sign into Tailscale and approve its VPN/system extension.
- Authenticate AWS, Jira, GitHub, OpenCode providers, and MCP servers.
- Sign into the App Store if a selected application requires it.
- Approve accessibility, notifications, screen recording, or automation prompts.
- Perform the separately approved logout/login or reboot validation.

## Recovery And Reruns

Bootstrap stores only non-secret progress under
`~/Library/Application Support/macos-nix-bootstrap`. Reruns validate actual state
and reuse the same identity. They do not silently regenerate keys or update the
source directory. Each apply archives a fresh immutable Nix store snapshot.

If build or secret readiness fails, no switch is attempted. If activation fails,
read the reported partial state before retrying; a first installation may not have
an earlier nix-darwin generation to roll back to. Never remove `/nix` or uninstall
Lix as an automatic recovery step.

Logs and support output must not contain identity contents, decrypted values,
authentication URLs with tokens, or complete environment dumps.
