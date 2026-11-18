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

Manjikaze provides a convenient menu option to update all installed applications:

1. Launch Manjikaze
2. Navigate to `Setup > Update installed apps`
3. The system will update all installed packages using both `pacman` and `yay`

## Tools Pinned with mise

Some command-line tools lag months behind in the Arch repositories. Manjikaze installs those with [mise](https://mise.jdx.dev) at a version it pins. The Scaleway CLI (`scw`) is the first:

- `configs/mise/<tool>.toml`, named after the mise tool, holds the pinned version. Installing the tool copies it to `~/.config/mise/conf.d/manjikaze-<tool>.toml`, next to your own `~/.config/mise/config.toml`. Manjikaze overwrites that copy, so don't edit it.
- `Update installed apps` copies the pinned versions again and lists the versions that aren't installed yet under "mise tools". They are installed when you proceed with the update.
- A project can pin another version in its own `mise.toml`.
- For `scw`, mise checks the download against the `SHA256SUMS` that Scaleway publishes.

To roll out a new version, change it in `configs/mise/<tool>.toml` in a pull request. Pick a release that is a few days old, so a broken or compromised release has time to come to light. Workstations install it with their first update after Manjikaze itself has updated.

## Update Frequency

It's recommended to run the update command at least every two weeks to keep your system up-to-date. Regular updates help maintain:

- System security
- Application stability
- Access to the latest features
- Compatibility with new software

For Arch-based systems like Manjaro, staying current is especially important due to the rolling release nature of the distribution.
