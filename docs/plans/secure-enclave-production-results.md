# Secure Enclave Production Foundation Results

## Implemented

The shared foundation now uses one plugin-aware age package for Home Manager's
agenix runtime and the repository-pinned agenix CLI. `age-plugin-se` is installed
for both profiles, and each host record supplies its runtime identity path.

Kagi is one shared secret declaration selected by both personal and work. The
current ciphertext and recipient rule remain unchanged, so the existing personal
host continues using `/Users/ajax/.ssh/bitwarden`. A future work host must provide
its own device-bound identity path and must be enrolled as a recipient before it
can activate the shared Kagi secret.

The flake exports:

- `agenix`: pinned agenix using plugin-aware age.
- `age-secure-enclave`: age with `age-plugin-se` on its explicit runtime PATH.
- `age-plugin-se`: the pinned plugin package.
- `agenix-se-keygen`: guarded unattended Secure Enclave identity enrollment.

The key generator requires one absolute output path, refuses existing identities
and recipient files, requires a private user-owned parent directory, uses access
control `none`, writes files with mode `0600`, and prints only the public recipient.
It is never run by evaluation, build, activation, or tests.

The justfile now uses `nix run .#agenix`, supports `AGENIX_IDENTITY` for selecting
an identity, and exposes explicit key-generation and recipient-inspection recipes.

## Explicitly Not Implemented

- No real Secure Enclave identity was generated on this machine.
- Existing Kagi ciphertext was not decrypted, rekeyed, or modified.
- No recovery private key or custody scheme was created.
- GitHub, Terraform Cloud, and Jira ciphertext cannot be created until the real
  work device recipient and credential migration session are available.
- `OPENAI_API_KEY` remains excluded.
- No OpenCode startup coordinator/wrapper was added. OpenCode startup ordering and
  credential refresh remain a separate decision, not an assumed age requirement.
- No persistent login/reboot test or system activation was performed.

## Verification

The software-only checks validate profile isolation, shared Kagi selection,
distinct host identity paths, plugin/agenix package availability, enrollment path
safety, permissions, no-overwrite behavior, and malformed invocation handling.

Commands run successfully:

```sh
nix flake check --no-write-lock-file 'path:.'
nix build --no-write-lock-file --no-link \
  'path:.#darwinConfigurations.Alexs-MacBook-Air.system'
```

The complete personal system built with the plugin-aware agenix runtime. These
commands did not activate Home Manager, load a launch agent, access a plaintext
secret, or invoke Secure Enclave key generation.

## Enrollment Gate

On each actual Mac, generate the device-bound identity only after confirming its
host record's identity path:

```sh
nix run .#agenix-se-keygen -- /absolute/private/path/identity.txt
```

Transfer only the printed `age1se...` public recipient to an authorized device.
That device updates `secrets/secrets.nix` and rekeys the applicable ciphertext.
The private identity file stays on the enrolled Mac and outside Git/Nix.

Kagi's rule will include both enrolled device recipients plus the separately
approved recovery recipient. Work-only token rules will not include the personal
recipient unless explicitly approved.
