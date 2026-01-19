# Window Tiling with Tactile

Manjikaze includes the Tactile extension, a configurable window tiling tool for GNOME that lets you organize windows in predefined zones using keyboard shortcuts.

## Tactile Keyboard Shortcuts

The primary way to use Tactile is through its keyboard-driven tiling system:

1. Press `Super + T` to activate Tactile's tiling mode
2. While still in tiling mode, press a letter key to place the active window in a specific zone

### Default Zone Mappings

When you press `Super + T`, you can then press one of these keys to position your window:

| Key | Position |
|-----|----------|
| `Q` | Top-left quarter |
| `W` | Top half |
| `E` | Top-right quarter |
| `A` | Left half |
| `S` | Center/full screen |
| `D` | Right half |
| `Z` | Bottom-left quarter |
| `X` | Bottom half |
| `C` | Bottom-right quarter |

For example, `Super + T` followed by `A` will position the window in the left half of the screen.

## Customizing Tactile

Tactile can be customized to fit your preferred workflow:

1. Open GNOME Extensions Manager
   - You can find this in your applications menu or run `extension-manager` in a terminal
2. Find the Tactile extension and click on the settings/gear icon
3. In the Tactile settings, you can:
   - Modify the keyboard shortcuts
   - Add new layouts
   - Change the margin between windows
   - Adjust the animation speed

## Advanced Layouts

Tactile supports various predefined layouts beyond the basic zones:

### Layout Examples

- **3-Column Layout**: Divide the screen into three vertical columns
- **2x2 Grid**: Create a grid of four equal sections
- **Main + Side Layout**: One large section with smaller sections to the side

You can define and activate these through the Tactile settings in Extension Manager.

## Moving Windows Between Workspaces and Monitors

In addition to Tactile's positioning features, you can move windows between workspaces and monitors:

### Workspace Movement

| Shortcut | Action |
|----------|--------|
| `Shift + Super + 1` | Move current window to workspace 1 |
| `Shift + Super + 2` | Move current window to workspace 2 |
| `Shift + Super + 3` | Move current window to workspace 3 |

### Monitor Movement

| Shortcut | Action |
|----------|--------|
| `Shift + Super + Left` | Move window to the monitor on the left |
| `Shift + Super + Right` | Move window to the monitor on the right |
