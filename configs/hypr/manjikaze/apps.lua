-- Default applications. Override any of these in ~/.config/hypr/hyprland.lua
-- before require("manjikaze"), e.g. manjikaze_apps = { terminal = "kitty" }.

local helpers = require("manjikaze.helpers")

local overrides = manjikaze_apps or {}

local apps = {
  terminal = helpers.first_present("alacritty", "kitty", "foot", "kgx", "gnome-terminal") or "xterm",
  files = "nautilus --new-window",
  editor = helpers.first_present("cursor", "code") or "gnome-text-editor",
  -- uwsm-app resolves the desktop entry of whatever browser is the XDG default.
  browser = [["$(xdg-settings get default-web-browser)"]],
}

for key, value in pairs(overrides) do
  apps[key] = value
end

return apps
