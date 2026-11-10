# Terminal

Manjikaze uses Alacritty as the default terminal emulator, with Zellij available as a terminal multiplexer, providing a powerful and flexible terminal workspace experience.

## Alacritty

Alacritty is a GPU-accelerated terminal emulator focused on performance and simplicity. Key benefits include:

- Minimal resource usage with GPU-accelerated rendering
- Excellent font rendering with proper emoji support
- Configured with CaskaydiaMono Nerd Font for programming

### Launch Shortcuts

Alacritty starts a plain Zsh shell. Use a separate shortcut to start it with a multiplexer:

| Shortcut | Action |
|----------|--------|
| `Super + Return` | Alacritty |
| `Super + Alt + Return` | Alacritty with Zellij |
| `Super + Ctrl + Return` | Alacritty with Herdr (when the optional `herdr` app is installed) |

Zellij and Herdr both claim keyboard shortcuts, so don't run Herdr inside Zellij. See [Herdr Agent Workspace](shell-tools.md#herdr-agent-workspace).

### Alacritty Shortcuts

| Shortcut | Action |
|----------|--------|
| `F11` | Toggle fullscreen mode |

## Zellij

Zellij is a terminal workspace with a focus on keyboard-driven productivity. It provides multiple tabs and panes within a single terminal window, along with session persistence.

### Tab Management

| Shortcut | Action |
|----------|--------|
| `Ctrl + T, N` | Create a new tab |
| `Ctrl + T, R` | Rename current tab |
| `Ctrl + T, X` | Close current tab |
| `Alt + Tab number` | Switch to tab by number (1-9) |
| `Alt + Left/Right` | Navigate to previous/next tab |

### Pane Management

| Shortcut | Action |
|----------|--------|
| `Ctrl + P, R` | Create a new pane to the right |
| `Ctrl + P, D` | Create a new pane below |
| `Ctrl + P, X` | Close current pane |
| `Alt + Arrow keys` | Navigate between panes |
| `Ctrl + P, W` | Toggle floating pane |
| `Ctrl + P, E` | Embed floating pane / Float embedded pane |

### Scrolling and Searching

| Shortcut | Action |
|----------|--------|
| `Ctrl + S` | Enter scroll mode |
| `↑/↓` | Scroll up/down (when in scroll mode) |
| `Page Up/Down` | Scroll page up/down (when in scroll mode) |
| `Ctrl + S, E` | Enter scroll edit mode (opens history in editor) |
| `Ctrl + S, /` | Search in scroll history |
| `n/N` | Find next/previous match (when searching) |
| `Esc` | Exit scroll mode |

### Session Management

| Shortcut | Action |
|----------|--------|
| `Ctrl + O, D` | Detach from session (preserves your workspace) |
| `Ctrl + O, W` | List available sessions |
| `Ctrl + G` | Lock/unlock the keyboard (sends all keys to active pane) |

## Terminal Shell

Manjikaze uses Zsh as the default shell with Oh My Zsh framework for enhanced functionality:

- Agnoster theme with helpful visual indicators
- Pre-configured plugins for common development tasks
- Automatic updates enabled

For more information about the shell tools and plugins included with Manjikaze, see the [Shell Tools](shell-tools.md) documentation.

## Configuration Files

If you want to customize your terminal experience, the relevant configuration files are:

- Alacritty: `~/.config/alacritty/alacritty.toml`
- Zellij: `~/.config/zellij/config.kdl`
- Zsh: `~/.zshrc`
