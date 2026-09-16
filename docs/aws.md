# AWS CLI

The work profile installs AWS CLI v2 and adds `aws-profile`, a Fish helper that
selects an AWS profile for the current shell. AWS configuration and
authentication otherwise use the standard AWS CLI.

## OpenCode AWS MCP access

The work profile installs `aws-mcp-profile-proxy`. It discovers AWS CLI profiles
matching the configured profile globs when it starts and allows those profiles
to be selected independently for each AWS MCP tool call.
Authenticated calls must always specify `aws_profile`; there is no implicit
runtime default. The first matching profile is used only to establish the MCP
connection during startup.

Configure the local MCP server in OpenCode with:

```jsonc
"aws-mcp": {
  "type": "local",
  "command": [
    "/etc/profiles/per-user/alexander.jackson/bin/aws-mcp-profile-proxy"
  ],
  "environment": {
    "AWS_MCP_PROFILE_PATTERNS": "ReadOnlyUpsideEngineerAccess-*"
  },
  "timeout": {
    "startup": 100000
  }
}
```

`AWS_MCP_PROFILE_PATTERNS` accepts whitespace-separated, case-sensitive shell
globs. For example, `"ReadOnlyUpsideEngineerAccess-* dev-*"` allows profiles
matching either pattern. If omitted, it defaults to
`ReadOnlyUpsideEngineerAccess-*`.

The proxy pins `mcp-proxy-for-aws-cli` and uses `uv`'s cache after its first
download. Restart the MCP server after adding a new matching AWS profile.

## Initial setup

After applying the work configuration with `nixre`, the AWS aspect seeds an
`upside` SSO session in `~/.aws/config` if that session is missing. Existing
profiles, comments, and session settings are preserved, and the file stays
writable by the AWS CLI.

Run the AWS IAM Identity Center configuration wizard:

```fish
aws configure sso
```

Enter **`upside`** at the SSO session name prompt; do not leave it blank, since
that selects legacy configuration. The CLI reuses the saved start URL, region,
and registration scope. Select `us-east-1` as the default client region.

For reference, or when configuring before the first activation, the values are:

| Prompt | Value |
| --- | --- |
| SSO session name | `upside` |
| SSO start URL | `https://upside-services.awsapps.com/start` |
| SSO region | `us-east-1` |
| SSO registration scopes | `sso:account:access` |
| Default client region | `us-east-1` |

Choose the account, role, and profile name that fit the work you need to do.
Profiles using the same `upside` SSO session share its sign-in session.

## Daily use

Select a configured profile interactively, then authenticate with the native
AWS CLI command:

```fish
aws-profile
aws sso login
aws sts get-caller-identity
```

You can select a known profile directly:

```fish
aws-profile my-profile
```

`aws-profile` exports `AWS_PROFILE` for the current Fish shell and child
processes, including Terraform and AWS SDKs. It removes stale explicit AWS
credential variables, which otherwise take precedence over profiles.

Clear the selected profile and those overrides with:

```fish
aws-profile --clear
```

This does not sign out. Use `aws sso logout` to remove cached IAM Identity
Center sessions.
