# Todoist

The Todoist app is installed via the `todoist-appimage` AUR package.
Because it's an AppImage, it mounts itself to a temporary directory each run
(e.g., `/tmp/.mount_todoisDSLD4N/todoist`). All rules use a regex to match
this dynamic path: `^/tmp/\.mount_todois.*/todoist$`.

## Rules

### 000 – Deny tracking (priority)

Blocks all telemetry, APM, and tracking endpoints (evaluated first):
- `browser-intake-datadoghq.com` (Datadog APM/logging)
- `o476415.ingest.sentry.io` (Sentry crash reporter)
- `googletagmanager.com` & `www.google-analytics.com` (Analytics)

### 001 – Allow DNS

Todoist's Electron layer ignores the system DNS resolver and makes direct
UDP port 53 queries to `1.1.1.1`, `8.8.8.8`, and `8.8.4.4`. This rule allows
DNS resolution.

### 002 – Allow core domains

Allows necessary APIs and CDNs:
| Domain | Purpose |
|---|---|
| `*.todoist.com` | Primary API, websockets (`ws.`) and app platform (`app.`) |
| `*.todoist.net` | Feature flags (`feat-flags.`), downloads (`electron-dl.`), AI (`aist.`) |
| `*.b-cdn.net` | Static assets CDN |
| `*.ctfassets.net` | Contentful CDN (often used for rich notifications/images) |
| `*.cloudfront.net` | Amazon Cloudfront CDN |
