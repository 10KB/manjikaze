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
5. **The rest:** mise runtimes, Cursor, removing packages that nothing depends on anymore, and a reboot when the system needs one.

## When the Update Asks for a Reboot

The update asks for a reboot only when the system shows it needs one, also when there was nothing to update:

- **The running kernel was replaced.** A kernel package removes the modules of the version it replaces, so the running kernel can't load drivers it hasn't loaded yet.
- **The CPU microcode was updated** since the system booted. Microcode loads at boot.
- **The NVIDIA driver was updated** and the loaded driver is older, so apps that use the GPU fail until a reboot.
- **A migration changed something** that only applies after a reboot.

An unattended update says why a reboot is needed, and doesn't reboot.

## Firmware Updates

Firmware for the BIOS, SSDs, docks and other devices comes from the [LVFS](https://fwupd.org) through fwupd. At the end, the update refreshes the list of firmware updates and shows the Host Security ID and which devices have an update, or that the firmware is up to date. It installs no firmware: some firmware updates finish during a reboot into the firmware updater, so they need you there.

To install them, run `manjikaze firmware` or choose **Setup → Update firmware**. It shows the updates, asks, and then runs `fwupdmgr update`, which asks again before a device that needs a reboot. Keep a laptop on AC power.

Every update and `manjikaze firmware` keep fwupd's security report in `~/.local/state/manjikaze/host-security.json`, with the time of the check and the Host Security ID (HSI). The HSI rates how well the firmware protects the system: a higher level means more of its security features are on, and an `!` after it means fwupd found a problem while the system runs. `fwupdmgr security` lists the checks behind it.

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

## Tools Installed with mise

Some command-line tools lag months behind in the Arch repositories, and some release too often to pin. Manjikaze installs those with [mise](https://mise.jdx.dev): the Scaleway CLI (`scw`) and the [AI agents](../features/ai-agents.md).

- `configs/mise/<tool>.toml`, named after the mise tool, holds the version. Installing the tool copies it to `~/.config/mise/conf.d/manjikaze-<tool>.toml`, next to your own `~/.config/mise/config.toml`. Manjikaze overwrites that copy, so don't edit it.
- The version is pinned, as for `scw`, or `latest`, as for the AI agents. Manjikaze takes `latest` to mean the newest release that is at least a day old, so a broken or compromised release has time to come to light. The Cursor CLI is the exception: Cursor publishes only its newest release.
- `Update installed apps` copies the versions again. Under "mise tools" it lists the versions that aren't installed yet, and the newer releases of the tools on `latest`. They are installed when you proceed with the update.
- A project can pin another version in its own `mise.toml`, for shells inside that project.
- Desktop apps and other programs that don't run in a shell with mise active use links in `~/.local/bin` to the programs of Manjikaze's version. For a tool on `latest`, the link follows every upgrade. Manjikaze doesn't put mise's shims on their `PATH`: a shim takes its version from the `mise.toml` or `.tool-versions` of the directory it runs in, so a project could decide what runs on the host.
- For `scw` and Claude Code, mise checks the download against the checksum file that Scaleway and Anthropic publish. For Codex and the Antigravity CLI, there is no checksum file, so mise compares the download with the checksum that GitHub reports for the release. That catches a damaged download, but not a release that was replaced. Cursor publishes no checksum for its CLI, and its own installer doesn't check one either.

To roll out a new version of a pinned tool, change it in `configs/mise/<tool>.toml` in a pull request. Pick a release that is a few days old. Workstations install it with their first update after Manjikaze itself has updated.

## Tailscale

Tailscale updates itself, outside `Update installed apps`. Manjikaze installs it from the static binaries that Tailscale publishes and switches on Tailscale's automatic updates. `tailscaled` then installs each new stable release when Tailscale's coordination server offers it: it checks the download against Tailscale's signing keys and restarts. It waits while someone is connected to the workstation over Tailscale SSH.

- `tailscale version` shows the installed version. `sudo tailscale update` installs the latest release right away.
- `sudo tailscale set --auto-update=false` switches the automatic updates off. Tailscale then stays at its version until you run `sudo tailscale update`.
- Manjikaze only checks the first download against the checksum on Tailscale's own server, which catches a broken download and nothing more.

A workstation that had Manjaro's `tailscale` package moves to these binaries with a migration, when `tailscaled` is running. Your login, and a changed `/etc/default/tailscaled`, stay.

## Update Frequency

It's recommended to run the update command at least every two weeks to keep your system up-to-date. Regular updates help maintain:

- System security
- Application stability
- Access to the latest features
- Compatibility with new software

For Arch-based systems like Manjaro, staying current is especially important due to the rolling release nature of the distribution.
