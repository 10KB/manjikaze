# Spotify

Spotify is installed at `/opt/spotify/spotify`. The path is stable across updates
(the package manager handles updates in-place), so no version regex is needed.

## Rules

### 000 – Deny tracking and advertising (priority)

Blocks telemetry and ad-related domains before any allow rules are evaluated:

| Domain pattern | Purpose |
|---|---|
| `*.sentry.io` | Crash reporting / telemetry |
| `*.doubleclick.net` | Google ad serving |
| `*.googlesyndication.com` | Google ad network |
| `*.googleadservices.com` | Google ad tracking |

### 001 – Allow Spotify domains

Core domains required for music streaming and the application to function:

| Domain pattern | Purpose |
|---|---|
| `*.spotify.com` | Main service, API, web player |
| `*.scdn.co` | CDN for audio streaming, album art, playlist images |
| `*.spotifycdn.com` | App updates, UI assets |

### 002 – Allow Google services

Spotify uses an embedded Chromium browser and relies on several Google services:

| Domain | Purpose |
|---|---|
| `accounts.google.com` | Google SSO login |
| `mtalk.google.com` | Push notifications (FCM) for Spotify Connect |
| `clients2.google.com` | Update checks, license verification |
| `android.clients.google.com` | Client registration |
| `www.google.com` | OAuth redirects |
| `safebrowsing.googleapis.com` | URL safety checks (embedded browser) |

These are listed explicitly rather than using a wildcard to prevent Spotify
from reaching arbitrary Google endpoints.

### 003 – Allow LAN discovery

Spotify Connect is a core feature for casting music to Chromecast, smart speakers,
and other devices on the local network. Unlike Dropbox LAN Sync (which is a security
risk), Spotify Connect is actively used and expected to work.

| Target | Purpose |
|---|---|
| RFC1918 private ranges | Direct communication with local devices |
| `239.255.255.250` | SSDP multicast for device discovery |
| `224.0.0.251` | mDNS for local name resolution |

### 004 – Deny catch-all

Any connection not matching the rules above is denied.
