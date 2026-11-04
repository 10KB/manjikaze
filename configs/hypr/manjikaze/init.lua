-- Manjikaze Hyprland defaults. Loaded from ~/.config/hypr/hyprland.lua; don't edit these
-- files in place, override them there so updates keep working.

require("manjikaze.env")
require("manjikaze.input")
require("manjikaze.looknfeel")
require("manjikaze.windows")
require("manjikaze.monitors")
require("manjikaze.autostart")

if manjikaze_default_bindings ~= false then
  require("manjikaze.bindings")
end
