# Google Chrome

Chrome is installed at `/opt/google/chrome/chrome`.

Similar to Firefox, a web browser needs unrestricted network access since it connects to arbitrary destinations on the internet.

## Why no telemetry block rule?

Unlike Firefox, which uses a separate `pingsender` binary for telemetry, Chrome bundles its crash reporter (`crashpad`) and metrics (UMA) into the main `/opt/google/chrome/chrome` process.

Furthermore, Chrome sends its telemetry to `clients2.google.com` and `clients4.google.com`. We cannot block these domains in OpenSnitch without breaking core functionality, because Google also uses these exact same domains for:
- Chrome Sync (bookmarks, passwords)
- Extensions updates
- Google Safe Browsing checking

Blocking them at the network level will break Chrome.

## Best practices

Instead of an OpenSnitch deny rule, you should disable telemetry inside Chrome:
1. Go to `chrome://settings/syncSetup` and disable "Help improve Chrome's features and performance"
2. Install **uBlock Origin** to block generic web trackers and telemetry from third-party websites.

## Rules

### 000 – Allow all

Allow all connections from `/opt/google/chrome/chrome`.
