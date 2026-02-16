# YubiKey GPG & SSH Setup

This page provides an in-depth technical explanation of how Manjikaze configures a YubiKey for GPG signing and SSH authentication. For the general YubiKey overview, see [YubiKey Integration](./yubikey.md).

For background reading, we recommend the [drduh/YubiKey-Guide](https://github.com/drduh/YubiKey-Guide). The de-facto standard reference for YubiKey GPG configuration.

## Why a YubiKey for GPG/SSH?

### Traditional SSH Keys vs. YubiKey

| | Traditional SSH key | YubiKey |
|---|---|---|
| **Storage** | File on disk (`~/.ssh/id_rsa`) | Hardware chip inside YubiKey |
| **Compromise risk** | Private key can be copied | Private key is not extractable |
| **Authentication** | Whoever has the file has access | Physical possession + PIN + touch required |
| **Portability** | Must be copied to each machine | One YubiKey works everywhere |
| **Audit** | No visibility into key usage | Touch = physical confirmation per operation |

### Why GPG and Not FIDO2?

FIDO2/WebAuthn is modern and simple, but GPG offers more:

- **Git commit signing** - GitHub/GitLab show "Verified" on signed commits
- **Email encryption** - Optional, but possible with the same keys
- **Key hierarchy** - One master key with dedicated subkeys per function
- **Key rotation** - Subkeys can be renewed without replacing the master key
- **Broad compatibility** - Works with all SSH servers, no server-side changes needed

## Architecture

### GPG Key Hierarchy

```
┌──────────────────────────────────────────────┐
│  Certify Key (C) — Master Key                │
│  RSA 4096, never expires                     │
│  ⚠ NOT stored on the YubiKey                 │
│  → Backed up to Bitwarden + local files      │
│  → Only needed for key management            │
├──────────────────────────────────────────────┤
│                                              │
│  ┌──────────────┐ ┌──────────────┐ ┌────────────────┐
│  │ Sign Key (S) │ │ Encrypt (E)  │ │ Auth Key (A)   │
│  │ RSA 4096     │ │ RSA 4096     │ │ RSA 4096       │
│  │ 5 year exp.  │ │ 5 year exp.  │ │ 5 year exp.    │
│  │              │ │              │ │                │
│  │ → Git commits│ │ → Files      │ │ → SSH login    │
│  │ → GPG sign   │ │ → Email      │ │ → Git push     │
│  └──────────────┘ └──────────────┘ └────────────────┘
│  ▲ On YubiKey    ▲ On YubiKey    ▲ On YubiKey       │
└──────────────────────────────────────────────┘
```

The **Certify Key** (master key) is only used to:
- Create or renew subkeys
- Revoke the key if lost
- Sign other keys (web of trust)

After setup, the Certify Key is **removed from the system** and only kept as a backup (in Bitwarden).

The three **subkeys** are transferred to the YubiKey via `keytocard`. This is a one-way operation. The keys are only available on the YubiKey from that point forward.

See: [drduh/YubiKey-Guide — Create Subkeys](https://github.com/drduh/YubiKey-Guide#create-subkeys)

### SSH via GPG Agent

```
┌─────────────┐     ┌────────────┐     ┌──────────┐     ┌──────────┐
│ ssh client  │────→│ gpg-agent  │────→│ scdaemon │────→│ YubiKey  │
│             │     │ (SSH sock) │     │          │     │ Auth key │
└─────────────┘     └────────────┘     └──────────┘     └──────────┘
```

GPG-agent replaces the default SSH agent:

- `SSH_AUTH_SOCK` is pointed to gpg-agent's SSH socket
- SSH clients talk to gpg-agent as if it were a regular SSH agent
- gpg-agent delegates to scdaemon, which communicates with the YubiKey
- The private key never leaves the YubiKey. All cryptographic operations happen on the chip

This is configured via an oh-my-zsh plugin (`yubikey-gpg`) that sets `SSH_AUTH_SOCK` and `GPG_TTY` correctly.

See: [drduh/YubiKey-Guide — SSH](https://github.com/drduh/YubiKey-Guide#ssh)

## Security Model

### Three Layers of Protection

1. **Physical possession** - The YubiKey must be physically present
2. **User PIN** - Once per session (cached for 12 hours), unlocks cryptographic functions
3. **Touch** - Every individual operation (SSH login, Git sign, etc.) requires a physical touch

### KDF (Key Derived Function)

KDF is enabled on the YubiKey. This means the PIN is hashed before being transmitted to the card. Even in a man-in-the-middle attack on the USB connection, the actual PIN cannot be intercepted.

See: [drduh/YubiKey-Guide — Enable KDF](https://github.com/drduh/YubiKey-Guide#enable-kdf)

### PIN Retries

The PIN retry counter is set to **5** (increased from the default of 3). After 5 incorrect PIN attempts, the YubiKey's OpenPGP applet is locked and can only be reset with a full `ykman openpgp reset`, which erases all keys on the card.

::: info
The OpenPGP smart card specification does not support time-based retry counter resets. The counter only resets when the correct PIN is entered successfully.
:::

### Touch Policy

All three key slots (Sign, Encrypt, Auth) have touch policy set to `Cached`. This means every cryptographic operation requires a physical touch of the YubiKey, but the touch is **cached for 15 seconds** after use. This avoids repeated touches during batch operations like `git rebase` or squashing multiple commits.

The `yubikey-touch-detector` service displays a desktop notification when the YubiKey is waiting for a touch.

## Scripts

### `yubikey-setup-gpg.sh` - Initial Setup

Complete one-shot configuration, accessible via:

```bash
manjikaze
# Navigate to: Security → YubiKey GPG and SSH setup
```

The script performs the following steps:

1. **GPG configuration** - Clean `~/.gnupg` with secure defaults
2. **Pinentry detection** - Automatically selects `pinentry-gnome3` (GNOME) or `pinentry-gtk` (Hyprland/other)
3. **YubiKey preparation** - Enable KDF, set login data
4. **Key generation** - Certify key + 3 subkeys (Sign, Encrypt, Auth) with RSA 4096
5. **Backup** - Export keys and revocation certificate to Bitwarden
6. **Key transfer** - Move subkeys to YubiKey via a custom pinentry implementation
7. **System configuration** - SSH config, Git signing, oh-my-zsh plugin, systemd sockets
8. **PIN change** - Change User PIN and Admin PIN (strongly recommended)
9. **Touch policy** - Enable touch requirement for all key slots

::: details Technical Detail: Custom Pinentry for `keytocard`

The `keytocard` operation requires two different secrets: the key passphrase **and** the card admin PIN. GPG's `--passphrase` flag can only provide a single value for all PIN/passphrase prompts.

The solution is a temporary custom pinentry script that implements the [Assuan pinentry protocol](https://www.gnupg.org/documentation/manuals/assuan/) and inspects the `SETDESC` prompt to determine which secret to return:

```
GETPIN →
  if prompt contains "Admin PIN" → respond with card admin PIN
  else                           → respond with certify key passphrase
```

After the transfer, the original pinentry program is restored.
:::

### `yubikey-gpg-health.sh` - Health Check

Read-only diagnostic script, accessible via:

```bash
manjikaze
# Navigate to: Security → YubiKey GPG health check
```

Checks all aspects of the YubiKey/GPG/SSH configuration:

- **Hardware** - YubiKey type, serial number, firmware version
- **OpenPGP Card** - Keys present, KDF status, PIN retries
- **Key expiry** - Warnings for keys expiring within 90 days
- **Trust & Policies** - Ultimate trust, touch policies per slot
- **SSH** - Correct `SSH_AUTH_SOCK`, key file present, agent active
- **Git** - Signing key configured, commit/tag signing enabled
- **Services** - gpg-agent sockets, zsh plugin installed

### `yubikey-gpg-restore.sh` - Restore to New YubiKey

For when a YubiKey is lost or damaged, accessible via:

```bash
manjikaze
# Navigate to: Security → Restore GPG keys to new YubiKey
```

The script:

1. Retrieves the Certify Key backup from Bitwarden or local files
2. Imports the keys into a temporary GPG home (prevents conflicts)
3. Creates new subkeys (old ones are unusable without the original YubiKey)
4. Transfers subkeys to the new YubiKey
5. Updates local system configuration

## Daily Usage

After setup, daily usage is minimal:

```
Boot / new session:
  → First GPG/SSH operation asks for User PIN (once)
  → PIN is cached for 12 hours

Every operation after that:
  → ssh git@github.com    → touch YubiKey
  → git commit -S         → touch YubiKey
  → gpg --sign file.txt   → touch YubiKey
```

The `yubikey-touch-detector` service shows a desktop notification whenever the YubiKey is waiting for a touch, so you know exactly when to tap the key.

## YubiKey Applets

A YubiKey has multiple independent applets. This setup only configures the **OpenPGP** applet:

| Applet | Used for | Configured by Manjikaze |
|---|---|---|
| **OpenPGP** | GPG keys, SSH auth, Git signing | ✅ `yubikey-setup-gpg.sh` |
| **OATH** | TOTP/HOTP codes (e.g. AWS MFA) | ✅ `yubikey-aws-vault.sh` |
| **PIV** | X.509 certificates, smart card login | ❌ Not used |
| **FIDO2/U2F** | WebAuthn, passkeys | Works out-of-the-box |
| **OTP** | Yubico OTP, static passwords | Used for disk encryption / PAM |

The PIV applet may show warnings about default credentials in the Yubico Authenticator app.This is unrelated to the OpenPGP configuration and can be safely ignored.
