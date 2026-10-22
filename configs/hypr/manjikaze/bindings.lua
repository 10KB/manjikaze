-- Every bind carries a description: SUPER + K lists them all (manjikaze-hypr-keybindings).
-- Disable the defaults with manjikaze_default_bindings = false before require("manjikaze").

local helpers = require("manjikaze.helpers")
local apps = require("manjikaze.apps")

local bind = helpers.bind
local launch = helpers.launch
local script = helpers.script

-- Applications
bind("SUPER + RETURN", "Terminal", launch(apps.terminal))
bind("SUPER + E", "Files", launch(apps.files))
bind("SUPER + W", "Browser", launch(apps.browser))
bind("SUPER + C", "Code editor", launch(apps.editor))
bind("SUPER + SHIFT + S", "Slack", helpers.launch_or_focus("^slack$", "slack"))
bind("SUPER + SHIFT + D", "DBeaver", helpers.launch_or_focus("dbeaver", "dbeaver"))
bind("CTRL + SHIFT + ESCAPE", "System monitor", launch(apps.terminal .. " --class manjikaze-floating -e btop"))

-- Launcher and menus
bind("SUPER + SPACE", "Search apps, files and more", script("manjikaze-hypr-launcher"))
bind("SUPER + V", "Clipboard history", script("manjikaze-hypr-launcher") .. " -m clipboard")
bind("SUPER + period", "Emoji and symbols", script("manjikaze-hypr-launcher") .. " -m symbols")
bind("SUPER + K", "Keyboard shortcuts", script("manjikaze-hypr-keybindings"))
bind("SUPER + I", "Settings", script("manjikaze-hypr-menu") .. " settings")
bind("SUPER + ESCAPE", "Power menu", script("manjikaze-hypr-menu") .. " power")
bind("CTRL + ALT + DELETE", "Power menu", script("manjikaze-hypr-menu") .. " power")
bind("SUPER + L", "Lock screen", "loginctl lock-session")
bind("SUPER + N", "Notification center", "swaync-client --toggle-panel --skip-wait")

-- Settings shortcuts
bind("SUPER + P", "Displays", launch("nwg-displays"))
bind("SUPER + CTRL + A", "Sound settings", launch("pavucontrol"))
bind("SUPER + CTRL + B", "Bluetooth settings", launch("blueman-manager"))
bind("SUPER + CTRL + N", "Network settings", launch("nm-connection-editor"))
bind("SUPER + CTRL + SPACE", "Next keyboard layout", "hyprctl switchxkblayout all next")

-- Windows
bind("SUPER + Q", "Close window", hl.dsp.window.close())
bind("ALT + F4", "Close window", hl.dsp.window.close())
bind("SUPER + F", "Fullscreen", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
bind("SUPER + M", "Maximize", hl.dsp.window.fullscreen({ mode = "maximized" }))
bind("SUPER + T", "Toggle floating", hl.dsp.window.float({ action = "toggle" }))
bind("SUPER + J", "Toggle split direction", hl.dsp.layout("togglesplit"))
bind("SUPER + O", "Pop out window (float on top)", function()
  local window = hl.get_active_window()
  if not window then
    return
  end
  if window.floating and window.pinned then
    hl.dispatch(hl.dsp.window.pin({ action = "off" }))
    hl.dispatch(hl.dsp.window.float({ action = "off" }))
  else
    hl.dispatch(hl.dsp.window.float({ action = "on" }))
    hl.dispatch(hl.dsp.window.pin({ action = "on" }))
  end
end)

bind("SUPER + G", "Toggle tab group", hl.dsp.group.toggle())
bind("SUPER + ALT + LEFT", "Previous tab in group", hl.dsp.group.prev())
bind("SUPER + ALT + RIGHT", "Next tab in group", hl.dsp.group.next())

local directions = { LEFT = "l", RIGHT = "r", UP = "u", DOWN = "d" }
local nudges = { LEFT = { -60, 0 }, RIGHT = { 60, 0 }, UP = { 0, -60 }, DOWN = { 0, 60 } }

for key, direction in pairs(directions) do
  local name = key:lower()
  bind("SUPER + " .. key, "Focus window " .. name, hl.dsp.focus({ direction = direction }))
  bind("SUPER + SHIFT + " .. key, "Move window " .. name, hl.dsp.window.swap({ direction = direction }))
  bind(
    "SUPER + CTRL + " .. key,
    "Resize window " .. name,
    hl.dsp.window.resize({ x = nudges[key][1], y = nudges[key][2], relative = true }),
    { repeating = true }
  )
end

bind("SUPER + SHIFT + CTRL + LEFT", "Move window to left monitor", hl.dsp.window.move({ monitor = "l" }))
bind("SUPER + SHIFT + CTRL + RIGHT", "Move window to right monitor", hl.dsp.window.move({ monitor = "r" }))
bind("SUPER + SHIFT + CTRL + UP", "Move window to monitor above", hl.dsp.window.move({ monitor = "u" }))
bind("SUPER + SHIFT + CTRL + DOWN", "Move window to monitor below", hl.dsp.window.move({ monitor = "d" }))

bind("ALT + TAB", "Next window", function()
  hl.dispatch(hl.dsp.window.cycle_next())
  hl.dispatch(hl.dsp.window.bring_to_top())
end)
bind("ALT + SHIFT + TAB", "Previous window", function()
  hl.dispatch(hl.dsp.window.cycle_next({ next = false }))
  hl.dispatch(hl.dsp.window.bring_to_top())
end)

bind("SUPER + mouse:272", "Drag window", hl.dsp.window.drag(), { mouse = true })
bind("SUPER + mouse:273", "Resize window with mouse", hl.dsp.window.resize(), { mouse = true })

-- Workspaces
for i = 1, 10 do
  local key = tostring(i % 10)
  bind("SUPER + " .. key, "Workspace " .. i, hl.dsp.focus({ workspace = i }))
  bind("SUPER + SHIFT + " .. key, "Move window to workspace " .. i, hl.dsp.window.move({ workspace = i }))
end

bind("SUPER + TAB", "Next workspace", hl.dsp.focus({ workspace = "m+1" }))
bind("SUPER + SHIFT + TAB", "Previous workspace", hl.dsp.focus({ workspace = "m-1" }))
bind("SUPER + Page_Down", "Next workspace", hl.dsp.focus({ workspace = "m+1" }))
bind("SUPER + Page_Up", "Previous workspace", hl.dsp.focus({ workspace = "m-1" }))
bind("SUPER + mouse_down", "Next workspace", hl.dsp.focus({ workspace = "e+1" }))
bind("SUPER + mouse_up", "Previous workspace", hl.dsp.focus({ workspace = "e-1" }))
bind("SUPER + S", "Scratchpad", hl.dsp.workspace.toggle_special("scratchpad"))
bind("SUPER + ALT + S", "Move window to scratchpad", hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }))

-- Screenshots
bind("Print", "Screenshot of a region (annotate)", script("manjikaze-hypr-screenshot") .. " region")
bind("SUPER + Print", "Screenshot of a region (annotate)", script("manjikaze-hypr-screenshot") .. " region")
bind("SHIFT + Print", "Screenshot of the screen", script("manjikaze-hypr-screenshot") .. " screen")
bind("ALT + Print", "Screenshot of the active window", script("manjikaze-hypr-screenshot") .. " window")
bind("SUPER + SHIFT + C", "Pick a color", "pkill hyprpicker || hyprpicker --autocopy")

-- Volume, brightness and media keys show an on-screen display on the focused monitor.
local function osd(args)
  return function()
    local monitor = hl.get_active_monitor()
    local target = monitor and (" --monitor " .. helpers.shell_quote(monitor.name)) or ""
    hl.exec_cmd("swayosd-client" .. target .. " " .. args)
  end
end

local media = { locked = true, repeating = true }
bind("XF86AudioRaiseVolume", "Volume up", osd("--output-volume raise"), media)
bind("XF86AudioLowerVolume", "Volume down", osd("--output-volume lower"), media)
bind("XF86AudioMute", "Mute", osd("--output-volume mute-toggle"), { locked = true })
bind("XF86AudioMicMute", "Mute microphone", osd("--input-volume mute-toggle"), { locked = true })
bind("XF86MonBrightnessUp", "Brightness up", osd("--brightness raise"), media)
bind("XF86MonBrightnessDown", "Brightness down", osd("--brightness lower"), media)
bind("XF86AudioPlay", "Play/pause", osd("--playerctl play-pause"), { locked = true })
bind("XF86AudioPause", "Play/pause", osd("--playerctl play-pause"), { locked = true })
bind("XF86AudioNext", "Next track", osd("--playerctl next"), { locked = true })
bind("XF86AudioPrev", "Previous track", osd("--playerctl prev"), { locked = true })
