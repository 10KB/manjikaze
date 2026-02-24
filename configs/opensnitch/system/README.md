# System Services

Rules for system-level services that need network access.

## Rules

### 000 – Allow Avahi (LAN only)

Avahi provides mDNS/DNS-SD service discovery for finding printers, file shares,
Chromecast devices, and other services on the local network.

Restricted to:
- RFC1918 private ranges (10.x, 172.16-31.x, 192.168.x)
- mDNS multicast (`224.0.0.251`, `ff02::fb`)
- Link-local (`fe80::*`)

Avahi should never communicate with the internet.

### 001 – Allow NetworkManager (LAN)

NetworkManager needs LAN access for DHCP lease management and gateway
communication. Includes the broadcast address for DHCP discovery.

### 002 – Allow NetworkManager connectivity check

NetworkManager pings `connectivity.manjaro.org` to detect captive portals
(hotel/airport WiFi) and verify internet access. This is a standard
NetworkManager feature, not telemetry.

### 003 – Allow time synchronization

`systemd-timesyncd` synchronizes the system clock via NTP. Restricted to
`*.ntp.org` pool servers only. Accurate time is critical for TLS certificate
validation, logging, and security.

### 004 – Allow Python (LAN only)

Allow Python scripts to communicate on the local network for IoT/Home Assistant
device discovery (SSDP, mDNS) and direct LAN communication.

Uses a version-independent path regex (`/usr/bin/python3(.x)?`) to survive
Python version upgrades. No internet access — Python scripts needing internet
should trigger a popup for explicit approval.

### 005 – Allow localhost

Allow all processes to communicate via loopback (`127.0.0.0/8` and `::1`).
Local inter-process communication is essential for many applications and is
safe by definition — traffic never leaves the machine.

### 006 – Allow GPG keyservers

Allow `dirmngr` to fetch public keys from keyservers for package signature
verification and developer key imports:

| Domain | Purpose |
|---|---|
| `keyserver.ubuntu.com` | Ubuntu SKS keyserver pool |
| `keys.openpgp.org` | OpenPGP keyserver |
| `keyserver.pgp.com` | PGP keyserver |
| `*.archlinux.org` | Arch Linux WKD (openpgpkey subdomains) |

### 007 – Allow package management

Allow `yay`, `git-remote-http`, and `pacman` to access Arch/Manjaro repos:

| Domain | Purpose |
|---|---|
| `*.archlinux.org` | AUR, official repos, package databases |
| `*.manjaro.org` | Manjaro mirrors and repos |
