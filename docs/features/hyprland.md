# Hyprland Desktop

[Hyprland](https://hypr.land) is a tiling Wayland compositor. Manjikaze can install it as an alternative to GNOME, with everything you'd expect from a desktop: an app launcher with search, a top bar, notifications with quick settings, settings apps for Wi-Fi, VPN, Bluetooth, sound and displays, a lock screen and idle handling. The setup takes a lot of inspiration from [Omarchy](https://omarchy.org).

GNOME stays installed. You choose the desktop on the login screen and can switch back any time.

## Installation

1. Run `manjikaze` and choose **Setup → Choose optional apps → hyprland**, or **Configuration → Hyprland desktop**.
2. Pick which desktop starts when you log in.
3. Log out or reboot. On the login screen the gear icon lets you pick **Hyprland (uwsm-managed)** or **GNOME**.

Run **Configuration → Hyprland desktop** again at any time to update the configuration files or to change the default desktop. Files you changed yourself are only replaced after you confirm, and a backup is kept.

## First Steps

| Shortcut | Action |
|----------|--------|
| `Super + Space` | Search apps, files, calculator, emoji, clipboard and the web |
| `Super + K` | Searchable list of all keyboard shortcuts |
| `Super + I` | Settings: Wi-Fi, VPN, Bluetooth, sound, displays, appearance |
| `Super + Esc` | Power menu: lock, suspend, log out, restart, shut down |
| `Super + N` | Notifications and quick settings |

The bar at the top works with the mouse too: click the network, Bluetooth or volume icon for quick menus, right-click for more.

## Keyboard Shortcuts

The most used shortcuts are below; `Super + K` always shows the complete, current list.

### Applications

| Shortcut | Action |
|----------|--------|
| `Super + Enter` | Terminal |
| `Super + E` | Files |
| `Super + W` | Browser (your default browser) |
| `Super + C` | Code editor (Cursor, or VS Code) |
| `Super + Shift + S` | Slack (focuses it when it's already open) |
| `Super + Shift + D` | DBeaver |
| `Ctrl + Shift + Esc` | System monitor |

### Windows

| Shortcut | Action |
|----------|--------|
| `Super + Q` / `Alt + F4` | Close window |
| `Super + ←/→/↑/↓` | Move focus |
| `Super + Shift + ←/→/↑/↓` | Move window |
| `Super + Ctrl + ←/→/↑/↓` | Resize window |
| `Super + Shift + Ctrl + ←/→` | Move window to the monitor on the left/right |
| `Super + F` | Fullscreen |
| `Super + M` | Maximize |
| `Super + T` | Toggle floating |
| `Super + O` | Pop out: float the window and keep it on top (video calls) |
| `Super + G` | Group windows as tabs, `Super + Alt + ←/→` switches tabs |
| `Super + J` | Toggle split direction |
| `Super + drag` | Move window with the mouse, right button resizes |
| `Alt + Tab` | Next window |

### Workspaces

| Shortcut | Action |
|----------|--------|
| `Super + 1` … `Super + 0` | Go to workspace 1–10 |
| `Super + Shift + 1` … `0` | Move window to workspace 1–10 |
| `Super + Tab` / `Super + Page Down` | Next workspace on this monitor |
| `Super + S` | Show/hide the scratchpad, `Super + Alt + S` moves a window there |

Each monitor starts with its own workspace. Three-finger swipes on a touchpad switch workspaces.

### Screenshots and System

| Shortcut | Action |
|----------|--------|
| `Print` / `Super + Print` | Screenshot of a region, annotate, `Enter` copies and saves |
| `Shift + Print` | Screenshot of the current monitor |
| `Alt + Print` | Screenshot of the active window |
| `Super + Shift + C` | Color picker |
| `Super + V` | Clipboard history |
| `Super + .` | Emoji and symbols (copied to the clipboard) |
| `Super + L` | Lock screen |
| `Super + P` | Displays |
| `Super + Ctrl + Space` | Next keyboard layout |

Screenshots are saved to `~/Pictures/Screenshots` and copied to the clipboard.

## Launcher

`Super + Space` opens [Walker](https://github.com/abenz1267/walker). Start typing to search apps, or use a prefix:

| Prefix | Searches |
|--------|----------|
| `=` | Calculator and unit conversion (`=3 * 1.21`, `=5 km to mi`) |
| `/` | Files |
| `.` | Emoji and symbols |
| `:` | Clipboard history |
| `@` | Web search; `gh:` searches GitHub and `mdn:` MDN |
| `>` | Run a command |
| `;` | All providers, including Bluetooth and sound devices |

## Settings

There is no single settings app like GNOME's. `Super + I` collects them in one menu:

- **Wi-Fi**: pick a network from the list. New networks ask for their password.
- **VPN**: connect or disconnect NetworkManager VPN and WireGuard connections.
- **Bluetooth and sound devices**: quick lists to connect devices or switch outputs.
- **Network connections**: wired, VPN and proxy settings (`nm-connection-editor`).
- **Bluetooth and sound settings**: Blueman and PulseAudio Volume Control.
- **Displays**: arrange monitors, see below.
- **Appearance**: GTK theme, icons and cursor (`nwg-look`).

The network and Bluetooth tray icons in the bar work like in GNOME, including password and pairing prompts.

## Monitors

Monitors are never configured by connector name or in a text file:

- **Any screen works right away**: it gets its native resolution at the highest refresh rate it supports at that resolution, is placed to the right of the other screens and is scaled by its pixel density.
- **Arrange once, remembered per set of screens**: open **Displays** (`Super + P`), drag the screens into position, set resolution or scale and click **Apply**. The layout is saved for that exact combination of screens and restored automatically whenever the same screens are connected, regardless of which port or dock they use. Your home desk and the three office monitors each keep their own layout.
- **Laptops**: unknown screens, such as a beamer, just extend the desktop. With the lid closed and an external screen connected, the laptop panel turns off.
- **Starting over**: **Settings → Reset display layout for these screens** removes the saved layout for the screens connected right now.

Screens are recognized by make, model and serial number. Two identical screens without a serial number fall back to the port they're connected to.

## Lock Screen and Idle

The screen locks after 5 minutes of inactivity and turns off 30 seconds later. Fullscreen video and video calls keep it on, and the coffee cup icon in the bar keeps it on manually. The computer never suspends by itself.

If you configured the YubiKey for the system (**Security → Configure Yubikey as MFA for system**), press `Enter` on the lock screen with the key inserted to unlock. **Security → Auto lock on Yubikey removal** works in Hyprland as well.

## Customizing

Your configuration lives in `~/.config/hypr/hyprland.lua`. It loads Manjikaze's defaults first, so updating Manjikaze improves the defaults without overwriting your changes. Add your own settings below the `require("manjikaze")` line:

```lua
-- Smaller gaps and square corners
hl.config({ general = { gaps_out = 4 }, decoration = { rounding = 0 } })

-- An extra shortcut
hl.bind("SUPER + SHIFT + G", hl.dsp.exec_cmd("uwsm-app -- gitkraken"), { description = "GitKraken" })

-- Remove a default shortcut
hl.unbind("SUPER + C")
```

To change the default apps, set them before `require("manjikaze")`:

```lua
manjikaze_apps = { terminal = "kitty", editor = "code" }
```

Hyprland reloads the configuration as soon as you save the file. Since version 0.55 Hyprland is configured in Lua; see the [Hyprland wiki](https://wiki.hypr.land/Configuring/Start/) for all options.

Other configuration files:

| File | Purpose |
|------|---------|
| `~/.config/waybar/` | Top bar |
| `~/.config/walker/`, `~/.config/elephant/` | Launcher |
| `~/.config/swaync/` | Notifications and quick settings |
| `~/.config/hypr/hyprlock.conf`, `hypridle.conf`, `hyprpaper.conf` | Lock screen, idle timeouts, wallpaper |
| `~/.config/uwsm/env-hyprland` | Session environment |

## Troubleshooting

- **Configuration errors** show up as a banner at the top of the screen. `hyprctl configerrors` lists them.
- **No bar or launcher**: make sure you picked **Hyprland (uwsm-managed)** on the login screen. The plain **Hyprland** entry starts without the session services.
- **Back to GNOME**: choose GNOME with the gear icon on the login screen, or run **Configuration → Hyprland desktop** and pick GNOME as default.
- **Services**: the bar, launcher, notifications and monitor handling run as user services. Check them with `systemctl --user status manjikaze-hyprland.target` and logs with `journalctl --user -u manjikaze-hypr-monitors`.
- **NVIDIA**: Hyprland needs kernel modesetting (`nvidia_drm.modeset=1`), which recent drivers enable by default. Manjikaze sets the NVIDIA environment variables only when the NVIDIA GPU drives the display, so hybrid laptops keep working video in browsers.
- **Clicking workspaces in the bar does nothing**: this needs Waybar 0.16 or newer. Manjikaze installs `waybar-git` while the repositories still ship 0.15.
