# Slack

Slack is installed at `/usr/lib/slack/slack`. The path is stable across updates.

## Rules

### 000 – Allow Slack domains

Core domains required for messaging and the app to function:

| Domain pattern | Purpose |
|---|---|
| `*.slack.com` | API, WebSocket connections, workspace access |
| `*.slack-edge.com` | Static assets, file downloads, avatars |
| `*.slack-imgs.com` | External link previews, unfurled images |
| `*.slackb.com` | Analytics beacons, workspace metrics |
| `*.atl-paas.net` | Atlassian (Jira/Confluence) integration previews |
| `*.atlassian.net` | Atlassian app icons and assets |

### 001 – Allow Chime (Huddles & calls)

Slack uses [Amazon Chime](https://aws.amazon.com/chime/) as its backend for audio/video:

| Domain pattern | Purpose |
|---|---|
| `*.chime.aws` | WebRTC signaling, TURN servers, media relay |

### 002 – Allow HTTPS (port 443)

Slack connects to many dynamic AWS IP addresses for Chime media relay, WebSocket
connections, and API endpoints. These connections often lack a hostname, so
domain-based rules (000, 001) alone are insufficient.

This rule allows Slack to connect to any destination on port 443 (TCP and UDP),
covering HTTPS, QUIC, and WebRTC traffic.
