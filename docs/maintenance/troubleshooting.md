# Troubleshooting

This guide covers common issues you might encounter while using Manjikaze and how to resolve them.

## Update Issues

### "Unable to lock database" Error

This error occurs when another package manager instance is running.

**Solution:**
Make sure to check if any package managers are running in the background (Software Update, Pamac, etc.). Wait till they're finished or close them. If that doesn't work you can try to manually remove the lock:

```bash
sudo rm /var/lib/pacman/db.lck
```

If that doesn't work, try:

```bash
sudo rm /var/tmp/pamac/dbs/db.lc
```

### "Unrecognized archive format" Error

This error occurs when the package database files are corrupted or incomplete.

**Solution:**

```bash
sudo pacman-mirrors -c Global
sudo pacman -Syu
```

### Key and Signature Errors

If you encounter key or signature verification errors:

**Solution:**

```bash
sudo pacman-key --refresh-keys
sudo pacman-key --populate archlinux manjaro
sudo pacman -Syu
```

### Conflicting Files Error

When pacman reports conflicting files:

**Solution:**

1. Identify which package owns the file:

   ```bash
   pacman -Qo /path/to/file
   ```

2. Either remove the conflicting package or back up and delete the conflicting file.

## System Issues

### System Slow After Update

If your system becomes slow after an update:

**Solution:**

1. Check for service issues:

   ```bash
   systemctl --failed
   ```

2. Check journal logs for errors:

   ```bash
   journalctl -p 3 -xb
   ```

### Application Crashes

For applications crashing after an update:

**Solution:**

1. Try reinstalling the application:

   ```bash
   sudo pacman -S application-name
   ```

2. Check if downgrading helps (use with caution):

   ```bash
   sudo downgrade application-name
   ```

## Recovery Options

If your system becomes unbootable after an update, you need to take additional steps to work around the full disk encryption:

1. Boot from a Manjaro Live USB
2. Decrypt your encrypted partition using your YubiKey:

   ```bash
   sudo cryptsetup open --type luks /dev/sdXY your_encrypted_volume
   ```

   (You'll need to insert your YubiKey when prompted)
3. Mount your decrypted system:

   ```bash
   sudo mount /dev/mapper/your_encrypted_volume /mnt
   sudo mount /dev/sdXZ /mnt/boot  # If you have a separate boot partition
   ```

4. Chroot into your system:

   ```bash
   sudo arch-chroot /mnt
   ```

5. Run system updates or repair commands
6. When finished:

   ```bash
   exit
   sudo umount -R /mnt
   sudo cryptsetup close your_encrypted_volume
   ```

For more complex issues, consult the [Manjaro Wiki](https://wiki.manjaro.org) or seek help in the Manjaro community forums.

---

[← Migrations](migrations.md) | [Documentation Home](../README.md)
