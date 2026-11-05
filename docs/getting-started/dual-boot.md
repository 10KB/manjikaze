# Dual Boot

Manjikaze can share a computer with Windows, another Linux distribution such as Ubuntu, or a second Manjikaze installation. This page covers both directions:

- [Installing Manjikaze next to an existing operating system](#install-manjikaze-next-to-an-existing-os)
- [Installing another operating system next to Manjikaze](#install-another-os-next-to-manjikaze)

Full disk encryption makes dual booting harder than usual. Read [How Manjikaze Boots](#how-manjikaze-boots) and [Risks and Known Issues](#risks-and-known-issues) before changing any partitions.

::: danger Back up first
Every partitioning step on this page can destroy data if you select the wrong partition. Back up everything that isn't stored in a remote Git repository, and make sure your passwords, recovery keys and YubiKey secrets are in Bitwarden before you start.
:::

## How Manjikaze Boots

The standard [installation](installation.md) ("Erase disk" with "Encrypt system") creates this layout:

| Partition | Mounted at | Contains | Encrypted |
|---|---|---|---|
| EFI System Partition (ESP), FAT32 | `/boot/efi` | GRUB bootloader in `EFI/Manjaro/grubx64.efi` and a fallback copy in `EFI/boot/bootx64.efi` | No |
| LUKS partition, ext4 | `/` | Everything else, **including `/boot`**: kernels, initramfs and the GRUB menu | Yes |

During boot:

1. The UEFI firmware starts GRUB from the ESP.
2. GRUB asks for your password and unlocks the LUKS partition. This is the step that takes about a minute, because GRUB's key derivation is slow.
3. GRUB reads its menu from `/boot/grub` and loads the kernel and initramfs.
4. The initramfs opens the root partition again. If you configured [YubiKey disk encryption](../security/disk-encryption.md), this is where it asks for your YubiKey.

This has consequences for every dual boot setup:

- **The GRUB menu is encrypted.** GRUB asks for the Manjikaze password *before* it shows the menu. Anyone who wants to start another operating system through Manjikaze's GRUB needs your password first.
- **Other operating systems can't see Manjikaze.** `os-prober`, which GRUB uses to find other systems, can't look inside an encrypted partition. Ubuntu's GRUB won't list Manjikaze, and Manjikaze's GRUB won't list an encrypted Ubuntu or a second Manjikaze. On Manjaro, `os-prober` is also disabled by default.
- **The ESP is shared and unencrypted.** All operating systems on a disk normally share one ESP and each writes its own folder to it. Installers and bootloader updates can overwrite or reorder each other's boot entries.

## Recommended Approach

Use the **UEFI firmware boot menu** to choose an operating system. Every operating system keeps its own bootloader and its own encryption, and you pick one at power-on with the one-time boot menu key (usually `F12`, `F11`, `F8` or `Esc`, depending on the manufacturer). Nobody needs to enter the Manjikaze password to start the other system.

If the computer has room for two drives, **install each operating system on its own disk**. Each disk then has its own ESP and the systems can't overwrite each other's bootloader files. This is the safest setup, and the only one we recommend for two Manjikaze installations.

You can also add the other operating system to Manjikaze's GRUB menu. See [Adding a GRUB Menu Entry](#adding-a-grub-menu-entry).

## Risks and Known Issues

| Risk | What happens | Prevention |
|---|---|---|
| Data loss while partitioning | Formatting or deleting the wrong partition destroys an operating system or its data | Back up first. Never format an existing ESP. Check the installer summary before you confirm |
| BitLocker recovery | Windows asks for the BitLocker recovery key after boot changes: a new bootloader, a changed boot order, disabled Secure Boot, or booting Windows through GRUB | Save the recovery key in Bitwarden and suspend BitLocker before you change anything |
| Secure Boot | Manjaro does not support Secure Boot, so it must be off. Turning it off changes the TPM measurements BitLocker relies on | Suspend BitLocker before you turn off Secure Boot |
| Windows Fast Startup | Windows hibernates instead of shutting down. Its NTFS partitions stay locked and can be damaged when another OS writes to them | Turn off Fast Startup and hibernation |
| Another OS takes over booting | Windows and Ubuntu set their own bootloader as the default. Manjikaze seems to be gone, but it's only lower in the boot order | Use the firmware boot menu or [fix the boot order](#fixing-the-boot-order) |
| Encrypted systems not detected | `os-prober` can't find operating systems on encrypted partitions | Use the firmware boot menu or a [chainload entry](#adding-a-grub-menu-entry) |
| Second Manjaro overwrites the first | Every Manjaro installs GRUB to `EFI/Manjaro` and registers a boot entry named "Manjaro". `grub-install` removes existing boot entries with the same name. Manjaro's `install-grub` hook runs `grub-install` again on GRUB updates | Give each Manjikaze installation its own ESP. See [Second Manjikaze](#second-manjikaze) |
| YubiKey secret overwritten | **Generate Yubikey secret for disk encryption** reprograms YubiKey slot 2. Every other installation that uses that secret can no longer unlock with the YubiKey | Generate the secret only once. On a second installation, skip that step |
| Ubuntu encryption limits | The Ubuntu Desktop installer (24.04 and later) only offers encryption when it erases the whole disk | Install Ubuntu on its own disk, or check the release notes of the version you install |
| Windows encrypts itself | A clean Windows 11 (24H2 or later) install turns on device encryption automatically on supported hardware | Save the recovery key right after you install Windows |
| GRUB can't unlock LUKS2 with Argon2 | Converting Manjikaze's partition to LUKS2 with the Argon2 key derivation (a common tip in other guides) makes it unbootable with GRUB | Don't convert the Manjikaze partition |
| Clock differences | Windows keeps the hardware clock in local time and Linux keeps it in UTC, so the clock is wrong after switching | See [Clock Differences](#clock-differences) |

### Security Considerations

- **Only dual boot with operating systems you trust.** The ESP is unencrypted. Someone with administrator rights on the other operating system can replace Manjikaze's GRUB with a modified version that records your password. This is the "evil maid" attack described in [Disk Encryption](../security/disk-encryption.md#limitations).
- **The other operating system is not managed by Manjikaze.** Security audits, updates and YubiKey integration only apply to Manjikaze. Keep your work and your secrets in Manjikaze.
- **Encrypt the other operating system too.** An unencrypted operating system can't read Manjikaze's encrypted data, but everything stored on the unencrypted system is readable by anyone with access to the computer.

## Install Manjikaze Next to an Existing OS

Use this when Windows, Ubuntu or another Linux is already installed and you want to add Manjikaze to the same disk.

### Preparations

Complete the regular [preparations](preparations.md) first. Then, in the existing operating system:

1. **Check the boot mode**
   - Both operating systems must boot in UEFI mode
   - Windows: run `msinfo32` and check that "BIOS Mode" says "UEFI"
   - Linux: check that the directory `/sys/firmware/efi` exists

2. **Save the BitLocker recovery key** (Windows only)
   - Run `manage-bde -protectors -get C:` in an administrator terminal, or find the key at [aka.ms/myrecoverykey](https://aka.ms/myrecoverykey) if you sign in with a Microsoft account
   - Store the recovery key in Bitwarden

3. **Suspend BitLocker** (Windows only)
   - Run in an administrator PowerShell:

   ```powershell
   Suspend-BitLocker -MountPoint "C:" -RebootCount 0
   ```

   - BitLocker stays suspended until you resume it after the installation

4. **Turn off Fast Startup and hibernation** (Windows only)
   - Run in an administrator terminal:

   ```powershell
   powercfg /h off
   ```

5. **Free up disk space**
   - Shrink the existing partition from the existing operating system itself. It knows its own file system best
   - Windows: open Disk Management, right-click the Windows partition and choose "Shrink Volume"
   - Linux: shrink the partition with GParted from a live USB. If the existing Linux is encrypted, see [Making Room on an Encrypted Disk](#making-room-on-an-encrypted-disk)
   - Leave the freed space **unallocated**. Plan for at least 100 GB; Docker images and dependencies add up quickly

6. **Turn off Secure Boot**
   - Open the UEFI firmware settings and turn off Secure Boot. The exact steps depend on the manufacturer

### Installation

Follow the [installation guide](installation.md), but use manual partitioning in step 5 (Disk Partitioning) instead of "Erase disk":

1. **Choose "Manual partitioning"**
   - Select your SSD
   - Don't use "Erase disk", which removes the existing operating system
   - Calamares also offers "Install alongside", which shrinks a partition for you. We don't recommend it: it can't shrink BitLocker partitions, and manual partitioning shows exactly what will change

2. **Reuse the existing EFI System Partition**
   - Select the existing FAT32 partition with the `boot` or `esp` flag (usually 100–500 MB)
   - Click "Edit", set the mount point to `/boot/efi` and choose **Keep** as content
   - **Never format this partition**. It contains the bootloader of the existing operating system

3. **Create the encrypted Manjikaze partition**
   - Select the unallocated space and click "Create"
   - File system: `ext4`, mount point: `/`
   - Check **Encrypt** and enter your secure password twice

4. **Check the summary**
   - The summary step must only mention the new partition and mounting the existing ESP
   - If it mentions formatting or deleting any existing partition, go back

5. **Continue with the regular installation**
   - Finish the [Manjaro installation](installation.md#manjaro-installation) and the [Manjikaze installation](installation.md#manjikaze-installation) as usual, including the YubiKey setup

### After Installation

1. **Check that both systems start**
   - After installation the computer starts Manjikaze's GRUB by default
   - Start the other operating system through the firmware boot menu
   - Optionally make one of them the default by [fixing the boot order](#fixing-the-boot-order)

2. **Resume BitLocker** (Windows only)
   - Start Windows and run in an administrator PowerShell:

   ```powershell
   Resume-BitLocker -MountPoint "C:"
   ```

   - If Windows asks for the recovery key on the first start, enter it once. Windows then accepts the new boot configuration

3. **Fix the clock** if needed. See [Clock Differences](#clock-differences)

## Install Another OS Next to Manjikaze

Use this when Manjikaze is already installed and you want to add Windows, Ubuntu or a second Manjikaze.

### Making Room on an Encrypted Disk

The standard Manjikaze installation uses the whole disk for one encrypted partition. There are three ways to make room for another operating system:

1. **Use a second disk (recommended)**
   - Install the other operating system on its own disk and leave the Manjikaze disk untouched
   - You can temporarily disconnect the Manjikaze disk while installing the other operating system, so the installer can't touch it

2. **Reinstall Manjikaze (recommended for a single disk)**
   - Manjikaze is designed to be reproduced with one command, so a reinstall is usually less work than resizing an encrypted partition
   - Back up your home directory and secrets, install the other operating system first, then follow [Install Manjikaze Next to an Existing OS](#install-manjikaze-next-to-an-existing-os)

3. **Shrink the encrypted partition (advanced)**
   - This means shrinking three layers in the right order from a live USB: the ext4 file system, then the LUKS container, then the partition. A mistake in the sizes destroys the data
   - We don't support this procedure. If you do it anyway, make a full backup and a LUKS header backup (`cryptsetup luksHeaderBackup`) first

### Windows

1. **Prepare Manjikaze**
   - Make sure you have unallocated space on the disk, or a second disk
   - Turn off Secure Boot if you turned it on

2. **Install Windows**
   - In Windows Setup, select the **unallocated space** and click "Next". Windows creates its own partitions there and reuses the existing ESP
   - Don't delete or format any existing partition. Windows shows the Manjikaze partition as an unknown partition

3. **Prepare Windows**
   - Save the BitLocker recovery key in Bitwarden. A clean Windows 11 install often turns on device encryption automatically
   - Turn off Fast Startup and hibernation with `powercfg /h off`

4. **Restore Manjikaze**
   - Windows makes Windows Boot Manager the default. Manjikaze's files and boot entry still exist
   - Start Manjikaze through the firmware boot menu, then [fix the boot order](#fixing-the-boot-order) if you want Manjikaze as default

Windows updates can move Windows Boot Manager back to the top of the boot order. Use the firmware boot menu or fix the boot order again when this happens.

### Ubuntu or Another Linux Distribution

1. **Check encryption support**
   - The Ubuntu Desktop installer (24.04 and later) only offers encryption when it erases the whole disk. Install Ubuntu on a second disk if it must be encrypted
   - Other distributions differ. Check whether their installer can encrypt a partition you create in free space

2. **Install the distribution**
   - Use the manual partitioning option ("Something else" or "Manual installation" in Ubuntu)
   - Create the new partitions in the unallocated space only
   - Use the existing ESP as EFI System Partition, mounted at `/boot/efi`, **without formatting it**
   - Don't touch the Manjikaze LUKS partition

3. **Restore Manjikaze**
   - The new distribution makes its own GRUB the default, and its GRUB won't list Manjikaze
   - Start Manjikaze through the firmware boot menu, then [fix the boot order](#fixing-the-boot-order) or [add a menu entry](#adding-a-grub-menu-entry) to the other GRUB

### Second Manjikaze

Two Manjaro installations use the same bootloader folder (`EFI/Manjaro`) and the same boot entry name ("Manjaro"). Installing the second one replaces the first one's boot entry, and every GRUB update on either system can do it again. Keep the two installations apart with a separate ESP for each:

1. **Install on a second disk if possible**
   - Every disk gets its own ESP, so the two installations can't overwrite each other's files
   - The firmware boot menu usually shows each disk separately and starts its fallback bootloader (`EFI/boot/bootx64.efi`), which Manjaro keeps up to date

2. **On a single disk, create a second ESP**
   - Choose "Manual partitioning" in the installer
   - In the unallocated space, create a 512 MiB `FAT32` partition with mount point `/boot/efi` and the `boot` flag
   - Create the encrypted `ext4` root partition in the remaining space as described in [Installation](#installation)
   - Don't select the first installation's ESP or LUKS partition

3. **Create a boot entry for each installation**
   - Give each installation its own boot entry with a name that doesn't contain "Manjaro", so `grub-install` won't remove it. For example, from either installation:

   ```bash
   sudo efibootmgr --create --disk /dev/nvme0n1 --part 1 --label "Manjikaze Work" --loader '\EFI\Manjaro\grubx64.efi'
   sudo efibootmgr --create --disk /dev/nvme0n1 --part 4 --label "Manjikaze Test" --loader '\EFI\Manjaro\grubx64.efi'
   ```

   - Replace the disk and partition numbers with those of each ESP. `lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINTS` shows them
   - After the next GRUB update, check with `efibootmgr` that both entries still exist

4. **Set up the YubiKey without overwriting it**
   - In the Manjikaze menu of the second installation, **skip "Generate Yubikey secret for disk encryption"**. Running it reprograms the YubiKey and locks the first installation out of YubiKey unlocking
   - Run "Configure Yubikey as MFA for disk encryption" directly. It uses the secret already on your YubiKey with a new challenge for this installation
   - "Configure Yubikey as MFA for system" is safe to run on both installations
   - If you ever [replace your YubiKey](../security/yubikey.md#replacing-a-faulty-yubikey), both installations keep working, because the new key gets the same secret

## Managing the Boot Menu

### Fixing the Boot Order

List the firmware boot entries and the current order from Manjikaze:

```bash
efibootmgr
```

Put the number of the entry you want as default first, for example:

```bash
sudo efibootmgr --bootorder 0003,0000,0001
```

You can also change the order in the UEFI firmware settings. If the Manjikaze entry is missing entirely, follow the Manjaro guide to [restore the GRUB bootloader](https://wiki.manjaro.org/index.php/Restore_the_GRUB_Bootloader).

### Adding a GRUB Menu Entry

A chainload entry starts another operating system's bootloader from GRUB. The other bootloader then handles its own encryption. This works in both directions:

- In **Manjikaze's GRUB**, an entry for another OS is only reachable after entering the Manjikaze password. It is convenient for you, not for other users of the computer
- In **another distribution's GRUB**, an entry for Manjikaze starts Manjikaze's GRUB, which then asks for the Manjikaze password as usual

::: warning BitLocker
Don't start Windows through GRUB on a BitLocker-encrypted system. GRUB changes the boot measurements BitLocker checks, which can make Windows ask for the recovery key on every start. Use the firmware boot menu for Windows.
:::

1. **Find the UUID of the ESP**

   ```bash
   lsblk -o NAME,FSTYPE,UUID,MOUNTPOINTS
   ```

   Use the UUID of the `vfat` partition that contains the bootloader, for example `1234-ABCD`.

2. **Add the entry** to the end of `/etc/grub.d/40_custom`. Keep the first lines of that file as they are:

   ```bash
   menuentry "Manjikaze" {
       insmod part_gpt
       insmod fat
       insmod chain
       search --no-floppy --fs-uuid --set=root 1234-ABCD
       chainloader /EFI/Manjaro/grubx64.efi
   }
   ```

   The `chainloader` path is relative to the ESP. Common paths:

   | Operating system | Bootloader path |
   |---|---|
   | Manjikaze | `/EFI/Manjaro/grubx64.efi` |
   | Ubuntu | `/EFI/ubuntu/shimx64.efi` |
   | Windows | `/EFI/Microsoft/Boot/bootmgfw.efi` |

3. **Regenerate the GRUB configuration**

   ```bash
   sudo update-grub
   ```

### Clock Differences

Windows keeps the hardware clock in local time and Linux keeps it in UTC, so the clock is off by your time zone offset after switching. Let Manjikaze use local time:

```bash
sudo timedatectl set-local-rtc 1 --adjust-system-clock
```

## Further Reading

- [Calamares: Deploy LUKS](https://github.com/calamares/calamares/wiki/Deploy-LUKS) - How Calamares sets up GRUB with an encrypted `/boot`
- [Manjaro forum: LUKS password prompt before GRUB](https://forum.manjaro.org/t/single-luks-password-prompt-before-grub-loads-preventing-easy-dual-boot-into-windows/85711) - Why the password is asked before the boot menu
- [Manjaro forum: install-grub](https://forum.manjaro.org/t/install-grub-a-new-way-to-keep-your-efi-mbr-in-sync-with-grub-package/154000) - The hook that reinstalls GRUB on updates
- [Manjaro forum: os-prober disabled by default](https://forum.manjaro.org/t/warning-os-prober-will-not-be-executed-to-detect-other-bootable-partitions/57849/2)
- [Ubuntu bug 1568050](https://bugs.launchpad.net/ubuntu/+source/grub2/+bug/1568050) - `grub-install` removes boot entries with the same name
- [Ubuntu Discourse: encryption only with full disk](https://discourse.ubuntu.com/t/24-04-disk-encryption-not-available-during-install-if-using-a-partition-and-not-full-disk/55238)
- [Microsoft: BitLocker recovery known issues](https://learn.microsoft.com/en-us/troubleshoot/windows-client/windows-security/bitlocker-recovery-known-issues)
- [Manjaro Wiki: Restore the GRUB Bootloader](https://wiki.manjaro.org/index.php/Restore_the_GRUB_Bootloader)
