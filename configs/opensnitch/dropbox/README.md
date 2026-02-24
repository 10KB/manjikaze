# Dropbox

Dropbox installs its binary in two possible locations:
- `~/.dropbox-dist/dropbox-lnx.x86_64-{VERSION}/dropbox` (user-installed)
- `/opt/dropbox/dropbox` (system-installed via package manager)

All rules use a regex for `process.path` that matches any user and any version number,
so rules don't need updating when Dropbox auto-updates.

## Rules

### 000 – Deny LAN scanning (priority)

Dropbox attempts to discover other Dropbox clients on the local network via
broadcast/multicast (LAN Sync). This exposes file metadata and could leak data to
unauthorized devices on shared networks.

This rule blocks all traffic to RFC1918 private ranges (10.x, 172.16-31.x, 192.168.x),
broadcast (255.255.255.255), and link-local (169.254.x) addresses.

> **Tip:** Also disable LAN Sync in Dropbox itself:
> *Preferences → Bandwidth → LAN Sync → Uncheck*

### 001 – Allow Dropbox domains

Allows connections to Dropbox-owned domains required for core functionality:

| Domain pattern | Purpose |
|---|---|
| `*.dropbox.com` | File sync, API, client communication, downloads |
| `*.dropboxstatic.com` | Static content, UI assets, updates |
| `*.dropbox-dns.com` | Dropbox DNS resolution (`geo.*`, `blackbox.*`) |

### 002 – Allow Dropbox IP ranges

Dropbox uses direct IP connections (without DNS) for file transfer and notification
channels. This rule allows only Dropbox-owned IP space (AS19679):

| Range | Size |
|---|---|
| `162.125.0.0/16` | Primary block (65k IPs) |
| `108.160.160.0/20` | Secondary block |
| `45.58.64.0/20` | Secondary block |
| `199.47.216.0/22` | Secondary block |

### 003 – Deny catch-all

Any connection from the Dropbox binary that doesn't match the allowed domains or IP
ranges above is denied. If Dropbox stops working after activation, check the OpenSnitch
logs for denied connections and add specific entries to rule `001` or `002` as needed.
