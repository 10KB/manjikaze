-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/

local helpers = require("manjikaze.helpers")

-- Tiling decides the size; ignore apps asking to be maximized.
hl.window_rule({ name = "suppress-maximize", match = { class = ".*" }, suppress_event = "maximize" })

-- Don't lock or blank the screen while something is fullscreen (video calls, presentations).
hl.window_rule({ name = "idle-inhibit-fullscreen", match = { class = ".*" }, idle_inhibit = "fullscreen" })

hl.window_rule({
  name = "fix-xwayland-drags",
  match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
  no_focus = true,
})

-- Settings tools and small utilities open as centered dialogs instead of tiles.
local dialogs = table.concat({
  "org.pulseaudio.pavucontrol",
  "blueman-manager",
  "nm-connection-editor",
  "nwg-look",
  "system-config-printer",
  "org.gnome.Calculator",
  "org.gnome.NautilusPreviewer",
  "xdg-desktop-portal-gtk",
  "hyprland-share-picker",
  "hyprpolkitagent",
  "com.gabm.satty",
  "manjikaze-floating",
}, "|")

hl.window_rule({ name = "float-dialogs", match = { class = "^(" .. dialogs .. ")$" }, float = true, center = true })
hl.window_rule({ name = "size-dialogs", match = { class = "^(" .. dialogs .. ")$", modal = false }, size = { 960, 640 } })

hl.window_rule({ name = "float-displays", match = { class = "^(nwg-displays)$" }, float = true, center = true, size = { 1200, 760 } })

-- Files (SUPER + E) opens as a window on top, like in GNOME; SUPER + T tiles it.
hl.window_rule({ name = "float-files", match = { class = "^(org.gnome.Nautilus)$" }, float = true, center = true })
hl.window_rule({ name = "size-files", match = { class = "^(org.gnome.Nautilus)$", modal = false }, size = { 1200, 760 } })

hl.window_rule({ name = "float-wallpaper-picker", match = { title = "^(Choose wallpaper)$" }, float = true, center = true })

-- Notes drawer (SUPER + `): Text Editor drops down from the bar on the focused screen and
-- hides again with the same shortcut. The editor keeps unsaved notes between sessions itself.
hl.workspace_rule({ workspace = "special:notes", on_created_empty = helpers.launch("gnome-text-editor") })
hl.window_rule({
  name = "notes-drawer",
  match = { class = "^(org.gnome.TextEditor)$" },
  workspace = "special:notes",
  float = true,
  size = { "monitor_w*0.7", "monitor_h*0.5" },
  move = { "monitor_w*0.15", "38" },
  -- Opening a file from elsewhere adds a tab and shows the drawer.
  focus_on_activate = true,
})

hl.window_rule({
  name = "float-file-pickers",
  match = { title = "^(Open|Save|Select|Choose).*" },
  float = true,
  center = true,
})

hl.window_rule({
  name = "picture-in-picture",
  match = { title = "^(Picture.in.[Pp]icture)$" },
  float = true,
  pin = true,
  keep_aspect_ratio = true,
  move = { "monitor_w-window_w-24", "monitor_h-window_h-24" },
  size = { "monitor_w*0.25", "monitor_h*0.25" },
})

-- Chrome's "... is sharing your screen" bar would otherwise grab a tile.
hl.window_rule({ name = "hide-sharing-indicator", match = { title = ".*is sharing (your screen|a window).*" }, workspace = "special:sharing silent" })

-- Blur behind the bar, launcher and notification center.
hl.layer_rule({ name = "blur-waybar", match = { namespace = "waybar" }, blur = true, ignore_alpha = 0.3 })
hl.layer_rule({ name = "blur-walker", match = { namespace = "walker" }, blur = true, ignore_alpha = 0.3 })
hl.layer_rule({ name = "blur-swaync", match = { namespace = "swaync-.*" }, blur = true, ignore_alpha = 0.3 })
hl.layer_rule({ name = "no-anim-selection", match = { namespace = "selection" }, no_anim = true })
