# AWS Tools

Manjikaze includes tools for working with AWS services securely using AWS Vault for credential management.

## AWS Vault

[AWS Vault](https://github.com/99designs/aws-vault) is a tool for securely storing and accessing AWS credentials in development environments. It stores your IAM credentials in your operating system's secure keystore and generates temporary credentials to expose to your shell and applications.

## Setting Up AWS Vault

### 1. Add Your IAM API Keys

First, add your 10KB IAM API keys to AWS Vault:

```bash
aws-vault add 10kb
```

This will prompt you for your Access Key ID and Secret Access Key, which will be stored securely in your system's keychain.

### 2. Configure Role Assumption

Edit your `~/.aws/config` file to set up roles that you want to assume. For example:

```ini
[profile manjikaze]
role_arn=arn:aws:iam::123456789:role/10KBDeveloperRole
source_profile=10kb
mfa_serial=arn:aws:iam::987654312:mfa/roland-10kb-username
```

This configuration allows you to assume the `10KBDeveloperRole` in the account with ID `123456789` using your `10kb` base credentials. The `mfa_serial` indicates that multi-factor authentication is required. Here the MFA device from your 10KB account is refered (since your using your 10KB credentials).

## Using AWS Vault

### Basic Usage

To run a command with your base credentials:

```bash
aws-vault exec 10kb -- aws s3 ls
```

This command lists S3 buckets in the 10KB account.

To assume a role and run a command:

```bash
aws-vault exec manjikaze -- aws s3 ls
```

This command lists S3 buckets in the manjikaze account after assuming the configured role.

### Docker Integration

AWS Vault can be used to provide AWS credentials to Docker containers, which is useful for testing AWS SDK integrations locally:

```bash
aws-vault exec manjikaze -- docker compose up backend
```

This starts a Docker container with the temporary AWS credentials for the manjikaze role.

> **Note**: Shell aliases defined in your profile are not available when using `aws-vault exec`. You must use the full command.

## Session Duration

By default, AWS Vault will request temporary credentials that last for 1 hour. You can modify this with the `--duration` flag:

```bash
aws-vault exec --duration=8h manjikaze -- aws s3 ls
```

## MFA Prompts

If your role or profile is configured with an MFA device, AWS Vault will prompt you for an MFA code when necessary. The session token obtained with an MFA code will be cached, so you won't need to enter it again until the session expires.

## Checking Active Sessions

To see all your active AWS Vault sessions:

```bash
aws-vault list
```

This displays your profiles, the credentials they're using, and any active sessions.

## YubiKey Integration

AWS CLI and SDKs do **not** support FIDO-U2F for MFA — even though U2F works in the AWS web console. To use a YubiKey with `aws-vault`, you need to use the YubiKey's **OATH-TOTP** capability, which stores a TOTP secret on the key and generates 6-digit codes on touch.

### Automated Setup

Run Manjikaze and navigate to **Security → Configure YubiKey for AWS Vault MFA**. The script will guide you through:

1. Creating a Virtual MFA device in AWS IAM
2. Storing the TOTP secret on your YubiKey
3. Activating the MFA device with two consecutive codes
4. Configuring `~/.aws/config` with `mfa_serial` and `mfa_process`

### How It Works

After setup, your `~/.aws/config` profiles will include:

```ini
[profile 10kb]
mfa_serial = arn:aws:iam::<account-id>:mfa/<device-name>
mfa_process = ykman oath accounts code --single arn:aws:iam::<account-id>:mfa/<device-name>
```

When you run `aws-vault exec <profile> -- <command>`, instead of prompting for a 6-digit code, `aws-vault` will call `ykman` which makes your YubiKey blink. Touch it, and the TOTP code is generated and passed to AWS automatically.

### Alternative: Using --prompt Flag

Instead of `mfa_process` in config, you can use the `--prompt` flag:

```bash
aws-vault exec --prompt ykman <profile> -- <command>
```

Or set it globally:

```bash
export AWS_VAULT_PROMPT=ykman
```

> **Important**: The `mfa_serial` must point to a **Virtual MFA device** (TOTP), not a U2F/FIDO security key. Both can coexist on the same IAM user — use U2F for console login and TOTP for CLI.

## Additional Resources

For more detailed information about AWS Vault, refer to the [official GitHub repository](https://github.com/99designs/aws-vault).
