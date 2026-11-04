-- Monitors are never hardcoded. In order of precedence (Hyprland uses the last matching rule):
--
--   1. Any screen gets its preferred resolution at the highest refresh rate it offers at
--      that resolution, is placed to the right of the others and scaled by pixel density.
--   2. A layout you arranged with Displays (SUPER + P, nwg-displays) is remembered for that
--      exact combination of screens and restored whenever the same screens are connected
--      (manjikaze-hypr-monitors keeps these profiles in ~/.local/state/manjikaze/hypr).
--   3. With the laptop lid closed and an external screen connected, the internal panel is off.

local helpers = require("manjikaze.helpers")

local profile_file = manjikaze.state_home .. "/manjikaze/hypr/monitor-profile.lua"

local function load_profile()
  if not helpers.file_exists(profile_file) then
    return { rules = {} }
  end
  local ok, profile = pcall(dofile, profile_file)
  if not ok or type(profile) ~= "table" or type(profile.rules) ~= "table" then
    return { rules = {} }
  end
  return profile
end

local profile = load_profile()

local function in_profile(monitor)
  for _, rule in ipairs(profile.rules) do
    local output = rule.output or ""
    if output == monitor.name then
      return true
    end
    local description = output:match("^desc:(.*)$")
    if description and (monitor.description or ""):sub(1, #description) == description then
      return true
    end
  end
  return false
end

local function best_mode(monitor)
  local modes = monitor.available_modes
  if type(modes) ~= "table" then
    return nil
  end

  local preferred
  for _, mode in ipairs(modes) do
    if mode.preferred then
      preferred = mode
      break
    end
  end
  if not preferred then
    return nil
  end

  local best = preferred
  for _, mode in ipairs(modes) do
    if mode.width == preferred.width and mode.height == preferred.height and mode.refresh_rate > best.refresh_rate + 0.5 then
      best = mode
    end
  end
  return string.format("%dx%d@%.3f", best.width, best.height, best.refresh_rate)
end

local function apply_automatic(monitor)
  if in_profile(monitor) then
    return
  end
  local mode = best_mode(monitor)
  if mode then
    hl.monitor({ output = monitor.name, mode = mode, position = "auto", scale = "auto" })
  end
end

local function is_internal(name)
  return name:match("^eDP") or name:match("^LVDS") or name:match("^DSI")
end

local function lid_closed()
  for _, lid in ipairs({ "LID0", "LID", "LID1", "LID2" }) do
    local state = helpers.read_file("/proc/acpi/button/lid/" .. lid .. "/state")
    if state then
      return state:find("closed", 1, true) ~= nil
    end
  end
  return false
end

-- A disabled panel disappears from hl.get_monitors() and Lua state doesn't survive a reload,
-- so connected panels are read from the kernel instead (only needed while the lid is closed).
local function connected_internal_panels()
  local panels = {}
  local pipe = io.popen("ls /sys/class/drm 2>/dev/null")
  if not pipe then
    return panels
  end
  for entry in pipe:lines() do
    local connector = entry:match("^card%d+%-(.+)$")
    if connector and is_internal(connector) then
      local status = helpers.read_file("/sys/class/drm/" .. entry .. "/status") or ""
      if status:match("^connected") then
        table.insert(panels, connector)
      end
    end
  end
  pipe:close()
  return panels
end

hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

local has_external = false
for _, monitor in ipairs(hl.get_monitors()) do
  if not is_internal(monitor.name) then
    has_external = true
  end
  apply_automatic(monitor)
end

for _, rule in ipairs(profile.rules) do
  hl.monitor(rule)
end

if has_external and lid_closed() then
  for _, name in ipairs(connected_internal_panels()) do
    hl.monitor({ output = name, disabled = true })
  end
end

local reload_timer
local function reload_soon()
  if reload_timer then
    reload_timer:set_enabled(false)
  end
  -- Reload from outside the callback; the config may not be torn down from within itself.
  reload_timer = hl.timer(function()
    hl.exec_cmd("hyprctl reload")
  end, { timeout = 400, type = "oneshot" })
end

hl.on("monitor.added", function(monitor)
  if lid_closed() then
    reload_soon()
  else
    apply_automatic(monitor)
  end
end)

-- Unplugging the last external screen with the lid closed must bring the panel back. The
-- panel itself being switched off (by the rule above) needs no reload.
hl.on("monitor.removed", function(monitor)
  if not is_internal(monitor.name) and lid_closed() then
    reload_soon()
  end
end)

hl.bind("switch:on:Lid Switch", reload_soon, { locked = true, description = "Laptop lid closed" })
hl.bind("switch:off:Lid Switch", reload_soon, { locked = true, description = "Laptop lid opened" })
