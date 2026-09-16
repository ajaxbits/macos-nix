# AWS CLI

The work profile installs AWS CLI v2 and adds `aws-profile`, a Fish helper that
selects an AWS profile for the current shell. AWS configuration and
authentication otherwise use the standard AWS CLI.

## Initial setup

Run the AWS IAM Identity Center configuration wizard:

```fish
aws configure sso
```

Use these company values when prompted:

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
