# Hyprland, Waybar & Rofi

This page explains how Manjikaze sets up the **Hyprland** Wayland compositor together with **Waybar** and **Rofi**, and how you can adapt the defaults to your liking.

---

## 1. Installing & Enabling Hyprland

1. Run `manjikaze` in a terminal.
2. Choose **Setup → Choose optional apps** and select **hyprland** (this also installs Waybar and Rofi). This also sets default configurations for Hyprland, Waybar and Rofi.
3. After the installation, open **Configuration → Select window manager** and pick **Hyprland**.

---

## 2. File Layout

| Path                              | Purpose                                                           |
|-----------------------------------|-------------------------------------------------------------------|
| `~/.config/hypr/hyprland.conf`    | Root file – imports the rest and starts Waybar/Hyprpaper/Hypridle |
| `~/.config/hypr/base.conf`        | Gaps, borders, animations, input defaults                         |
| `~/.config/hypr/keybindings.conf` | All shortcuts (see next section)                                  |
| `~/.config/hypr/theme.conf`       | Gruvbox colour palette                                            |
| `~/.config/hypr/rules.conf`       | Per-app rules (floating, size, etc.)                              |
| `~/.config/hypr/custom.conf`      | Empty – put your own overrides here (it is **never** overwritten) |
| `~/.config/waybar/*`              | Per-monitor Waybar config + CSS                                   |
| `~/.config/rofi/*`                | Rofi behaviour and theme                                          |

Hyprland will automatically enable hot reloading, so any change in config will immediatly take effect.

---

## 3. Default Keybindings

`$mainMod` is `SUPER` (the *Windows/Command* key).

Which applications are launched on a keybind can easily be changed by setting `$terminal`, `$fileManager`, `$browser` and `$menu` in `~/.config/hyprland.conf`.

| Action                                 | Keys                      |
|----------------------------------------|---------------------------|
| Open terminal (`kitty`)                | `Super + Enter`           |
| Open browser (`firefox`)               | `Super + Shift + Enter`   |
| Application launcher (Rofi)            | `Super + Space`           |
| Reload config                          | `Super + Esc`             |
| Close window                           | `Super + R`               |
| Lock screen                            | `Super + Z`               |
| Toggle floating                        | `Super + T`               |
| Move focus                             | `Super + H/J/K/L`         |
| Move window                            | `Super + Shift + H/J/K/L` |
| Resize window                          | `Super + Alt + H/J/K/L`   |
| Next / previous workspace              | `Super + W / Q`           |
| Move window to next / prev workspace   | `Super + Shift + W / Q`   |
| Focus next / prev monitor              | `Super + A / S`           |
| Move window to next / prev monitor     | `Super + Shift + A / S`   |
| Create new workspace                   | `Super + E`               |
| Move window into a new empty workspace | `Super + Shift + E`       |

---

## 4. Waybar

Waybar sits at the top of each monitor.
Configuration is JSONC (JSON with comments) and split per output (e.g. `bar_DP-2.jsonc`).
The default assumes 3 monitors, this can easily be configured.

* Modules are defined in `modules.jsonc` once and then referenced by each bar.
* Styling is done via `style.css` – regular CSS.
* Reload by running `pkill -SIGUSR2 waybar` or simply `hyprctl reload`.

A lot of information can be found on the [Waybar Wiki](https://github.com/Alexays/Waybar/wiki)

---

## 5. Rofi

Rofi provides the application launcher and a *Projects* mode that searches the `~/Projects` folder via a small shell script.

* Global settings live in `config.rasi`.
* Colours and spacing are in `theme.rasi`.
* Launch manually with `rofi -show run`.

To experiment, duplicate `theme.rasi`, update the path in `config.rasi`, reload (`Super + Esc`) and try it.

The script assumes a specific folder structure. It might not initially work, but it easily customizable to your flow.

---
[Cursor Installation →](cursor-installation.md) | [← Documentation Home](../README.md)