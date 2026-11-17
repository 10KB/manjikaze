# Yubikey Integration

Manjikaze integrates Yubikey hardware tokens to enhance system security. Yubikeys are hardware security devices that provide strong authentication and can be used for various security functions. This document outlines how Yubikey is used in Manjikaze.

## Yubikey Features in Manjikaze

Manjikaze supports the following Yubikey security features:

1. **Full Disk Encryption Authentication** - Use your Yubikey as a second factor when unlocking your encrypted disk during boot
2. **System Authentication** - Unlock the screen, use sudo and approve polkit prompts with your Yubikey and its PIN
3. **Auto-Lock on Removal** - Automatically lock your session when your Yubikey is removed

## Yubikey Touch Detector

The Yubikey Touch Detector is a utility that shows an on-screen notification when your Yubikey is waiting for a touch confirmation. This is particularly useful when using the Yubikey with applications that require touch confirmation without making it obvious that user interaction is required.

The notification helps you know exactly when you need to touch your Yubikey to confirm an operation, improving the user experience when working with touch-required operations.

## GPG & SSH Authentication

Manjikaze can configure your YubiKey as a hardware-backed GPG and SSH key. Private keys are generated directly on the YubiKey and **cannot be extracted**. All cryptographic operations happen on the chip.

Key features:
- **SSH authentication** - Use your YubiKey for SSH login (replaces `~/.ssh/id_rsa`)
- **Git commit signing** - Commits show as "Verified" on GitHub/GitLab
- **Three-layer security** - Physical possession + PIN (once per day) + touch (per operation)
- **Automated backup** - Keys and revocation certificates are backed up to Bitwarden
- **Health check** - Diagnostic script to verify your setup
- **Restore flow** - Restore keys to a new YubiKey if the original is lost

For a full technical explanation of the architecture, security model, and scripts, see the [YubiKey GPG & SSH Setup](./yubikey-gpg-ssh.md) guide.

## Yubikey for Full Disk Encryption

Using a Yubikey as a second factor for disk encryption adds a significant layer of security to your system. Manjikaze uses the [yubikey-full-disk-encryption](https://github.com/agherzan/yubikey-full-disk-encryption) package to implement this functionality.

To set up Yubikey for disk encryption:

1. First, configure your Yubikey slot for challenge-response mode:

    ```bash
    manjikaze
    ```

    Navigate to: Security → Generate Yubikey Secret for Disk Encryption

2. Then, configure the Yubikey for disk encryption. Navigate to: Security → Configure Yubikey as MFA for Disk Encryption

For more details about the disk encryption implementation, see the [Disk Encryption](disk-encryption.md) documentation.

## Yubikey for System Authentication

Manjikaze lets you use your Yubikey instead of your password for:

- Unlocking the screen (GNOME and hyprlock) and logging in on a console
- Sudo commands
- Polkit prompts (GUI password prompts)

To set it up:

```bash
manjikaze
```

Navigate to: Security → Configure Yubikey as MFA for System

The Yubikey alone is not enough. You type the Yubikey's FIDO2 PIN and then touch the key. If your Yubikey has no FIDO2 PIN yet, Manjikaze asks you to choose one.

Manjikaze uses [pam-u2f](https://developers.yubico.com/pam-u2f/) for this, with one line at the top of `/etc/pam.d/system-auth`. Sudo, polkit, GDM, login and hyprlock all include that file. Registrations live in `/etc/u2f_mappings`, which only root can change. Before changing PAM, Manjikaze backs up `/etc/pam.d` to `/etc/pam.d.backup-<time>`.

- **Use your password instead**: remove the Yubikey. Without a key, you get the password prompt right away. With the Yubikey inserted, the first prompt asks for its PIN: typing your password there counts as a wrong PIN.
- **Wrong PINs**: after 3 wrong PINs in a row, remove and reinsert the Yubikey. After 8 wrong PINs without a correct one in between, the FIDO2 PIN is blocked. Unblocking it means resetting the FIDO2 application, which also deletes the passkeys stored on that Yubikey.
- **Spare Yubikey**: run the menu item again with the spare inserted, and register it as an extra key.
- **Disk encryption**: is not affected. It keeps using the challenge-response secret in slot 2.
- **GNOME keyring**: logging in with the Yubikey does not unlock it, because you don't type your password. It asks for your password when an app needs it.

Earlier versions unlocked with a touch of the Yubikey alone. A migration removes that setup and offers to set up the PIN. If you skip it, you unlock with your password until you run the menu item.

### Test before you close your terminal

A mistake in PAM can lock you out of sudo, polkit and the lock screen at the same time. After setting it up:

1. Keep a root shell open in a separate terminal (`sudo -i`).
2. In a new terminal, run `sudo -k; sudo true`, then `pkexec true`.
3. Only then lock the screen and unlock it, in GNOME and in hyprlock if you use it.
4. Remove the Yubikey and check that your password still works.

If something fails, restore the backup of `/etc/pam.d` from the root shell.

## Auto-Lock on Yubikey Removal

Manjikaze can lock your session when your Yubikey is removed. This ensures that your workstation is locked if you walk away with your Yubikey.

To set up auto-lock on Yubikey removal:

```bash
manjikaze
```

Navigate to: Security → Auto Lock on Yubikey Removal

Inserting the Yubikey again does not unlock your session, because that would skip the PIN. You unlock with the Yubikey and its PIN, or with your password.

## Replacing a Faulty Yubikey

If your Yubikey is lost or damaged, you can replace it using the Manjikaze menu:

```bash
manjikaze
```

Navigate to: Security → Replace Faulty Yubikey

Follow the prompts to configure your new Yubikey with the same security features as your previous one. If you unlock with your Yubikey, Manjikaze then registers the new key for unlocking, sudo and polkit, and keys registered before stop working there.
