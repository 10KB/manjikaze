# Disk Encryption

Manjikaze implements full disk encryption to protect your data at rest. This document explains the disk encryption implementation, its security implications, and how to use it effectively.

## Overview

Manjikaze uses LUKS (Linux Unified Key Setup) for disk encryption, enhanced with Yubikey authentication for added security. This means your data is protected by both:

1. A strong password you know (something you know)
2. Your Yubikey hardware token (something you have)

This two-factor approach significantly improves security compared to password-only encryption.

## How It Works

### LUKS Encryption

LUKS (Linux Unified Key Setup) is the standard disk encryption method for Linux systems. It:

- Encrypts your entire disk, including the operating system
- Protects data from unauthorized access if your device is lost or stolen
- Uses strong AES-XTS encryption with 512-bit keys

### Yubikey Integration

Manjikaze extends standard LUKS by integrating Yubikey hardware tokens using the [yubikey-full-disk-encryption](https://github.com/agherzan/yubikey-full-disk-encryption) package. This integration:

- Uses the Yubikey's HMAC-SHA1 Challenge-Response mode
- Generates a unique, strong passphrase based on a challenge sent to the Yubikey
- Requires the physical Yubikey to be present during the boot process

## Security Implications

### Advantages

1. **True Two-Factor Authentication**: Requires both your password and your physical Yubikey
2. **Protection Against Offline Attacks**: Even if someone has physical access to your computer, they cannot decrypt your data without both factors
3. **Strong Key Derivation**: The Yubikey generates cryptographically strong keys that are resistant to brute force attacks
4. **Limited Attack Surface**: The encryption key never leaves your Yubikey, reducing the risk of key extraction

### Limitations

1. **Requires Yubikey Presence for Boot**: You must have your Yubikey available to boot your system
2. **Does Not Protect Against Evil Maid Attacks**: Physical tampering with the bootloader is still possible (though advanced measures like Secure Boot help mitigate this)
3. **No Protection for Running System**: Once the system is decrypted and running, the data is accessible to anyone with access to the system

## Setting Up Disk Encryption

Disk encryption should be set up during the initial Manjaro installation process, before installing Manjikaze. The Manjikaze installer provides options to configure Yubikey integration with an existing LUKS setup.

To add Yubikey authentication to your existing disk encryption:

1. First, configure your Yubikey for challenge-response mode:

    ```bash
    manjikaze
    ```

    Navigate to: Security → Generate Yubikey Secret for Disk Encryption

2. Then, configure disk encryption to use your Yubikey. Navigate to: Security → Configure Yubikey as MFA for Disk Encryption

## Recovery Options

It's critical to understand that if you lose both your password and your Yubikey, **your data will be permanently inaccessible**. There is no backdoor or recovery method.

For this reason we recommend:

1. Storing your password securely in your Bitwarden account
2. Backing up essential data to secure external storage
3. Consider storing a backup Yubikey in a secure location

## Technical Details

### Challenge-Response Mode

The Yubikey integration uses HMAC-SHA1 Challenge-Response mode, where:

1. A challenge (stored in /etc/ykfde.conf) is sent to the Yubikey during boot
2. The Yubikey computes an HMAC-SHA1 response using its internal secret key
3. This response becomes part of the encryption key material for unlocking the LUKS volume

### Boot Process

During boot, the following happens:

1. The initramfs loads the LUKS and Yubikey modules
2. The system prompts you to insert your Yubikey
3. A challenge is sent to the Yubikey
4. The Yubikey generates a response which is used to unlock the LUKS volume
5. The boot process continues with the decrypted system

## Security Recommendations

For maximum security with disk encryption:

1. Use a strong, unique password in addition to your Yubikey
2. Keep your Yubikey with you at all times, but separate from your computer when not in use
3. Enable the touch requirement on your Yubikey to prevent remote exploitation
4. Consider enabling auto-lock on Yubikey removal for additional protection

## Common Issues and Troubleshooting

### Cannot Boot Without Yubikey

This is by design.

### Replacing a Yubikey

If you need to replace your Yubikey:

```bash
manjikaze
```

Navigate to: Security → Replace Faulty Yubikey

---

[← Yubikey Integration](yubikey.md) | [Documentation Home](../README.md)
