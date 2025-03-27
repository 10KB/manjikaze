# Yubikey Integration

Manjikaze integrates Yubikey hardware tokens to enhance system security. Yubikeys are hardware security devices that provide strong authentication and can be used for various security functions. This document outlines how Yubikey is used in Manjikaze.

## Yubikey Features in Manjikaze

Manjikaze supports the following Yubikey security features:

1. **Full Disk Encryption Authentication** - Use your Yubikey as a second factor when unlocking your encrypted disk during boot
2. **System Authentication** - Configure your Yubikey for system login, sudo access, and other PAM authentication
3. **Auto-Lock on Removal** - Automatically lock, suspend, or log out when your Yubikey is removed

## Yubikey Touch Detector

The Yubikey Touch Detector is a utility that shows an on-screen notification when your Yubikey is waiting for a touch confirmation. This is particularly useful when using the Yubikey with applications that require touch confirmation without making it obvious that user interaction is required.

The notification helps you know exactly when you need to touch your Yubikey to confirm an operation, improving the user experience when working with touch-required operations.

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

Manjikaze allows you to use your Yubikey for system-wide authentication, including:

- Login authentication
- Sudo command authentication
- Polkit authentication (GUI password prompts)
- GNOME Keyring unlocking

To set up Yubikey for system authentication:

```bash
manjikaze
```

Navigate to: Security → Configure Yubikey as MFA for System

This configuration uses the PAM (Pluggable Authentication Modules) system to enable Yubikey challenge-response authentication. Once configured, you can authenticate by either:

1. Inserting your Yubikey and touching it when prompted, without typing your password
2. Using your password alone as a fallback when your Yubikey is not available

## Auto-Lock on Yubikey Removal

Manjikaze can be configured to automatically secure your system when your Yubikey is removed. This provides additional security by ensuring that your workstation is locked if you walk away with your Yubikey.

To set up auto-lock on Yubikey removal:

```bash
manjikaze
```

Navigate to: Security → Auto Lock on Yubikey Removal

You can choose from three actions when your Yubikey is removed:

1. **Lock** - Lock the screen, requiring authentication to unlock
2. **Suspend** - Lock the screen and put the system into sleep mode
3. **Logout** - End your current session completely

## Replacing a Faulty Yubikey

If your Yubikey is lost or damaged, you can replace it using the Manjikaze menu:

```bash
manjikaze
```

Navigate to: Security → Replace Faulty Yubikey

Follow the prompts to configure your new Yubikey with the same security features as your previous one.

---

[← Security](README.md) | [Disk Encryption →](disk-encryption.md)
