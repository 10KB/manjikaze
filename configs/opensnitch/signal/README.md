# Signal

Signal Desktop is installed at `/usr/lib/signal-desktop/signal-desktop`.
The path is stable across updates.

Signal is end-to-end encrypted and by design only communicates with its own
infrastructure — no third-party services are required.

## Rules

### 000 – Allow Signal domains

All Signal functionality runs on `*.signal.org`:

| Subdomain | Purpose |
|---|---|
| `chat.signal.org` | Messaging API, WebSocket connection |
| `cdn.signal.org`, `cdn2.signal.org` | Attachment and media delivery |
| `keys.signal.org` | Public key distribution |
| `storage.signal.org` | Encrypted contact/group backup |
| `updates.signal.org` | App update checks |

### 001 – Allow connectivity check

Signal pings `1.1.1.1` (Cloudflare DNS) to determine if the device has internet
connectivity. Without this, Signal may incorrectly report being offline.

### 002 – Deny catch-all

Any connection not matching the rules above is denied. Signal only uses its own
infrastructure, so this should rarely trigger.
