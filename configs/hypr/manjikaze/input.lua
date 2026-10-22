-- Keyboard layout follows the system setting (localectl set-x11-keymap), so it matches
-- GDM and the GNOME session without being hardcoded here.

local helpers = require("manjikaze.helpers")

local function system_keymap()
  local keymap = { layout = "us", variant = "", options = "" }
  local content = helpers.read_file("/etc/X11/xorg.conf.d/00-keyboard.conf")
  if not content then
    return keymap
  end

  keymap.layout = content:match('Option%s+"XkbLayout"%s+"([^"]*)"') or keymap.layout
  keymap.variant = content:match('Option%s+"XkbVariant"%s+"([^"]*)"') or keymap.variant
  keymap.options = content:match('Option%s+"XkbOptions"%s+"([^"]*)"') or keymap.options
  return keymap
end

local keymap = system_keymap()

hl.config({
  input = {
    kb_layout = keymap.layout,
    kb_variant = keymap.variant,
    kb_options = keymap.options,
    numlock_by_default = true,
    repeat_rate = 35,
    repeat_delay = 300,
    follow_mouse = 1,
    sensitivity = 0,

    touchpad = {
      natural_scroll = true,
      tap_to_click = true,
      disable_while_typing = true,
      clickfinger_behavior = true,
      scroll_factor = 0.5,
    },
  },

  misc = {
    key_press_enables_dpms = true,
    mouse_move_enables_dpms = true,
  },
})

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

return keymap
