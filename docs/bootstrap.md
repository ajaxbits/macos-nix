# Bootstrap A New Work Mac

The bootstrap starts with one dependency: a working Nix installation from the
[Lix installer](https://lix.systems/install/). Run it from the standard macOS
Terminal as your normal logged-in account, not from a root shell.

Bootstrap is intentionally guided and resumable. It will explain every mutation
and ask before generating a Secure Enclave identity, opening Apple's Command Line
Tools installer, installing Homebrew, cloning the repository, or switching the
system. `--check` is read-only apart from normal Nix fetching/build caching.

## Before Starting

You need two values from the reviewed configuration change:

- `REV`: the full 40-character Git commit containing the new Mac's host record.
- `HOST`: the exact `darwinConfigurations` output name for the new Mac.

At initial implementation time, this repository still exposes only the existing
personal Mac. The new work Mac must have a reviewed real host record before these
commands can be used. Bootstrap rejects unknown hosts and will not derive one from
the laptop, reuse the personal output, or invent work account details.

Do not use a moving branch name for the first switch.

Nix may ask whether to trust this flake's extra substituters and public keys:

- `https://cache.nix.ajax.casa/patroclus` (personal cache)
- `https://cache.garnix.io`
- `https://cache.numtide.com`

The bootstrap does not require the personal cache. Declining the flake settings is
supported; Nix can use its normal configured caches or build locally. Only accept
additional cache trust after reviewing the URL and key shown by Nix.

## 1. Check Readiness

```sh
nix --extra-experimental-features 'nix-command flakes' run \
  "github:ajaxbits/macos-nix/$REV#bootstrap" -- \
  --check --host "$HOST"
```

This checks the logged-in user, UID, home directory, Apple Silicon architecture,
LocalHostName, Lix, Command Line Tools, Homebrew, and configured age identity. It
does not use sudo, create a key, clone a repository, or activate nix-darwin.

If the host record does not match the new laptop, update and review the host record
instead of renaming an MDM-managed machine or letting bootstrap guess.

## 2. Generate The Device Identity

```sh
nix --extra-experimental-features 'nix-command flakes' run \
  "github:ajaxbits/macos-nix/$REV#bootstrap" -- \
  --prepare-enrollment --host "$HOST" --profile work
```

After confirmation, this creates an unattended Secure Enclave identity at the
host's configured private path. It uses `--access-control=none`, never overwrites
an identity, and prints only the public `age1se...` recipient.

On an already authorized device or through the recovery custodian:

1. Add the public recipient to the shared Kagi rule and intended work-secret rules.
2. Rekey the ciphertext with an already authorized identity.
3. Review and commit the host/rule/ciphertext changes.
4. Publish that commit and record its new full revision as `REV`.

Keep the private identity on the new Mac. Do not send it to the authorized device
or copy a recovery private key onto the laptop.

## 3. Resume And Apply

Run bootstrap from the newly reviewed enrollment revision:

```sh
nix --extra-experimental-features 'nix-command flakes' run \
  "github:ajaxbits/macos-nix/$REV#bootstrap" -- \
  --apply --host "$HOST"
```

Bootstrap then:

1. Reuses the existing Secure Enclave identity.
2. Creates or validates `~/code/macos-nix` at exactly `REV`.
3. Proves this device can decrypt every required ciphertext without printing it.
4. Opens Apple's Command Line Tools installer if needed, then asks you to rerun.
5. Installs Homebrew from the repository-pinned official installer if needed.
6. Runs the flake checks and builds from the exact immutable GitHub revision.
7. Revalidates the checkout and runs a privileged activation/collision check.
8. Shows the host/profile/source/system summary.
9. Requires a final `yes` before switching that same immutable revision.
10. Verifies nix-darwin is installed and the switched system still uses Lix.

Use `--checkout /absolute/path` to select another durable checkout. Bootstrap will
not reset or overwrite an existing dirty or unrelated checkout.

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
source revision.

If build or secret readiness fails, no switch is attempted. If activation fails,
read the reported partial state before retrying; a first installation may not have
an earlier nix-darwin generation to roll back to. Never remove `/nix` or uninstall
Lix as an automatic recovery step.

Logs and support output must not contain identity contents, decrypted values,
authentication URLs with tokens, or complete environment dumps.
