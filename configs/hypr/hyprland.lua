-- Hyprland configuration. Manjikaze's defaults load first; everything after them is yours.
-- Shortcuts: SUPER + K. Documentation: https://manjikaze.10kb.nl/features/hyprland
-- Hyprland reloads automatically when you save this file.

dofile("__MANJIKAZE_DIR__/configs/hypr/bootstrap.lua")

-- Change default apps or skip the default keybindings before loading the defaults:
-- manjikaze_apps = { terminal = "kitty", editor = "code" }
-- manjikaze_default_bindings = false

require("manjikaze")

-- Personal overrides, for example:
-- hl.config({ general = { gaps_out = 4 }, decoration = { rounding = 0 } })
-- hl.bind("SUPER + SHIFT + G", hl.dsp.exec_cmd("uwsm-app -- gitkraken"), { description = "GitKraken" })
-- hl.unbind("SUPER + C")
--
-- Monitors don't belong here: arrange them with Displays (SUPER + P) and the layout is
-- remembered per combination of connected screens.
