# Updates

Keeping your Manjikaze system up-to-date is crucial for security, stability, and access to the latest features. Manjikaze provides convenient methods to keep both itself and your installed applications updated.

## Manjikaze Self-Updates

Manjikaze automatically checks for updates each time you run the application. When an update is available, you'll be prompted to update with a simple confirmation dialog:

```
Updates available. Would you like to update Manjikaze?
```

It's recommended to approve these updates to ensure you have the latest features and security patches.

A [system package install](./system-package) skips this check: your package manager updates Manjikaze.

## Updating Installed Applications

Run `manjikaze update`, or start Manjikaze and choose **Setup → Update installed apps**. The update lists what can be updated and asks what to include. It then works in a fixed order:

1. **Checks.** At least 5 GiB has to be free on `/`; with less, Manjikaze asks before it goes on. It looks for updates with `checkupdates`, which leaves the system's package databases alone until the upgrade itself. The update installs `pacman-contrib` for this when it's missing.
2. **System packages.** Older versions are removed from the package cache, keeping the two newest of every package. pacman then syncs the package databases and upgrades in a systemd scope of its own, so an upgrade of systemd or a desktop session that ends can't stop it halfway. When the upgrade fails, the update stops here.
3. **Migrations.** Manjikaze can itself be one of the system packages, and [migrations](migrations.md) are written for the upgraded system, so they run after it.
4. **AUR packages**, the ones you selected. They are built against the system packages, so Manjikaze only offers them when the system packages are up to date or part of this update.
5. **The rest:** mise runtimes, Cursor, removing packages that nothing depends on anymore, and the question whether to reboot.

## Updating Without Questions

`manjikaze update -y` runs the whole update without asking anything, for example from a timer or when an administrator asks for an update:

- A git install of Manjikaze updates itself first. When local changes stand in the way, the update goes on with the version that is there; it never discards your changes.
- It updates the system packages, every AUR package that has an update, and Cursor, and it runs the pending migrations.
- With less than 5 GiB free on `/`, it stops instead of asking.
- It doesn't reboot. When the update needs a reboot, it says so.
- It exits with an error when it couldn't update, or when a migration or an AUR package failed. The other steps still run first.

sudo still asks for your password once when it needs one.

## Update Logs

Every update writes a log to `~/.local/state/manjikaze/updates/`, one file per update named after the time it started. That includes unattended updates and updates started from the menu. The log records everything the update showed, the questions included, with the start and end time and the exit code. Manjikaze keeps the 60 most recent logs.

At the end, the update checks its log for problems that exit codes don't show:

- **An initramfs image that wasn't built.** The system may not boot, so the update doesn't offer a reboot and ends with an error. Fix what mkinitcpio reports in the log and rebuild the images with `sudo mkinitcpio -P` before you reboot.
- **An initramfs image built with errors.** mkinitcpio wrote the image, but says it may not be complete. The update shows the errors; check them before you reboot.
- **DKMS modules that didn't build**, such as the driver for DisplayLink docks. They won't load after a reboot.
- **New `.pacnew` and `.pacsave` files:** configuration files that a package installed a new version of next to yours. Merge them, for example with `sudo pacdiff`.

## Tools Pinned with mise

Some command-line tools lag months behind in the Arch repositories. Manjikaze installs those with [mise](https://mise.jdx.dev) at a version it pins. The Scaleway CLI (`scw`) is the first:

- `configs/mise/<tool>.toml`, named after the mise tool, holds the pinned version. Installing the tool copies it to `~/.config/mise/conf.d/manjikaze-<tool>.toml`, next to your own `~/.config/mise/config.toml`. Manjikaze overwrites that copy, so don't edit it.
- `Update installed apps` copies the pinned versions again and lists the versions that aren't installed yet under "mise tools". They are installed when you proceed with the update.
- A project can pin another version in its own `mise.toml`, for shells inside that project.
- Desktop apps and other programs that don't run in a shell with mise active use links in `~/.local/bin` to the programs of the pinned version. Manjikaze doesn't put mise's shims on their `PATH`: a shim takes its version from the `mise.toml` or `.tool-versions` of the directory it runs in, so a project could decide what runs on the host.
- For `scw`, mise checks the download against the `SHA256SUMS` that Scaleway publishes.

To roll out a new version, change it in `configs/mise/<tool>.toml` in a pull request. Pick a release that is a few days old, so a broken or compromised release has time to come to light. Workstations install it with their first update after Manjikaze itself has updated.

## Update Frequency

It's recommended to run the update command at least every two weeks to keep your system up-to-date. Regular updates help maintain:

- System security
- Application stability
- Access to the latest features
- Compatibility with new software

For Arch-based systems like Manjaro, staying current is especially important due to the rolling release nature of the distribution.
