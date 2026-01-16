# WirePlumber 0.5.12 Downgrade - Bluetooth Audio Crash Fix

## The Problem

GNOME Shell crashes (with forced logout) when your Bluetooth headphones switch
from HD audio playback (A2DP) to handsfree mode (HSP/HFP), for example when
starting an online meeting.

### Root Cause

WirePlumber 0.5.13 introduces new Bluetooth profile autoswitch logic (MR #739/776)
that sends loopback nodes. GNOME's `libgnome-volume-control` cannot handle this
correctly yet and crashes.

**Related issues:**
- https://gitlab.freedesktop.org/pipewire/wireplumber/-/merge_requests/776
- https://gitlab.freedesktop.org/pipewire/pipewire/-/merge_requests/2654
- https://gitlab.gnome.org/GNOME/libgnome-volume-control/-/merge_requests/31

### Affected Configuration

| Package | Affected version |
|---------|------------------|
| wireplumber | 0.5.13 ❌ |
| gnome-shell | 49.x |
| pipewire | 1.4.9 |

## Solution: Downgrade to WirePlumber 0.5.12

> **Note:** If you're using manjikaze, the migration script handles this
> automatically. These manual steps are for debugging or standalone use.

### Step 1: Perform the downgrade

```bash
sudo pacman -U libwireplumber-0.5.12-1-x86_64.pkg.tar.zst \
               wireplumber-0.5.12-1-x86_64.pkg.tar.zst
```

### Step 2: Block updates temporarily

Run the included script:

```bash
sudo ./ignore-wireplumber-updates.sh
```

Or manually: add `IgnorePkg = wireplumber libwireplumber` to `/etc/pacman.conf`.

### Step 3: Restart WirePlumber

```bash
systemctl --user restart wireplumber
```

## When can I upgrade back to 0.5.13+?

Once GNOME's libgnome-volume-control MR #31 is merged and released in a
gnome-shell update. Check the status at:
https://gitlab.gnome.org/GNOME/libgnome-volume-control/-/merge_requests/31

After that, you can remove the IgnorePkg rule with:

```bash
sudo ./restore-wireplumber-updates.sh
```

---
*Last updated: 2026-01-16*
