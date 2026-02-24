# AWS

Rules for AWS tooling: `aws-vault`, AWS CLI v2, and SAM CLI.

## Rules

### 000 – Allow AWS services

Allow `aws-vault` and the AWS CLI to connect to AWS:

| Binary | Path | Purpose |
|---|---|---|
| `aws-vault` | `/usr/bin/aws-vault` | STS credential management, MFA |
| `aws` (CLI v2) | `/usr/local/aws-cli/*/aws` | All AWS service interactions |

Allowed domains:

| Domain | Purpose |
|---|---|
| `*.amazonaws.com` | All AWS service endpoints (S3, STS, CloudFormation, etc.) |
| `*.amazoncognito.com` | Cognito authentication |
| `*.amazonwebservices.com` | AWS console, documentation lookups |

The CLI path uses a version-independent regex to survive CLI updates.

### 001 – Allow CLI downloads

Allow `curl` to download AWS CLI updates from `awscli.amazonaws.com`.
Separate rule because `curl` is a shared binary — only this specific
domain is matched.

## SAM CLI

SAM CLI runs via Python and makes CloudFormation calls to `*.amazonaws.com`.
These are covered by the Python LAN rule for local invocations, and via
popup for remote deployments (which use the system Python or AWS CLI).
