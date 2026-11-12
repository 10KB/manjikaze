-- Monitors are never hardcoded. In order of precedence (Hyprland uses the last matching rule):
--
--   1. Any screen gets its preferred resolution at the highest refresh rate it offers at
--      that resolution, is placed to the right of the others and scaled by pixel density.
--   2. A layout you arranged with Displays (SUPER + P, nwg-displays) is remembered for that
--      exact combination of screens and restored whenever the same screens are connected
--      (manjikaze-hypr-monitors keeps these profiles in ~/.local/state/manjikaze/hypr).
--   3. With the laptop lid closed and an external screen connected, the internal panel is off.
--
-- With more than one screen, workspaces follow the screens from left to right; see
-- assign_workspaces below.

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

local function profile_rule(monitor)
  for _, rule in ipairs(profile.rules) do
    local output = rule.output or ""
    if output == monitor.name then
      return rule
    end
    local description = output:match("^desc:(.*)$")
    if description and (monitor.description or ""):sub(1, #description) == description then
      return rule
    end
  end
  return nil
end

local function in_profile(monitor)
  return profile_rule(monitor) ~= nil
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

-- Screens that show workspaces, from left to right. Positions come from the saved layout
-- when there is one, because right after login Hyprland hasn't placed the screens yet.
local function screens_left_to_right()
  local monitors = hl.get_monitors()
  local descriptions = {}
  local external = false
  for _, monitor in ipairs(monitors) do
    local description = monitor.description or ""
    descriptions[description] = (descriptions[description] or 0) + 1
    if not is_internal(monitor.name) then
      external = true
    end
  end
  local panel_off = external and lid_closed()

  local screens = {}
  for _, monitor in ipairs(monitors) do
    local rule = profile_rule(monitor) or {}
    local hidden = rule.disabled == true
      or (rule.mirror ~= nil and rule.mirror ~= "")
      or monitor.is_mirror
      or (panel_off and is_internal(monitor.name))
    if not hidden then
      local x, y = tostring(rule.position or ""):match("^(-?%d+)x(-?%d+)$")
      local description = monitor.description or ""
      table.insert(screens, {
        name = monitor.name,
        output = (description ~= "" and descriptions[description] == 1) and ("desc:" .. description) or monitor.name,
        x = tonumber(x) or monitor.x or 0,
        y = tonumber(y) or monitor.y or 0,
        order = monitor.id or 0,
      })
    end
  end

  table.sort(screens, function(a, b)
    if a.x ~= b.x then
      return a.x < b.x
    end
    if a.y ~= b.y then
      return a.y < b.y
    end
    return a.order < b.order
  end)
  return screens
end

-- Workspaces are numbered across the screens: with three screens 1, 2 and 3 are on the left,
-- middle and right one, then 4, 5 and 6, and so on. Each screen keeps
-- manjikaze_workspaces_per_monitor of them (default 2) in the bar, even when empty. Higher
-- numbers open on the focused screen. A single screen keeps Hyprland's dynamic workspaces.
local show_timer
local function assign_workspaces()
  local screens = screens_left_to_right()
  if #screens < 2 then
    return
  end

  local showing = {}
  for _, monitor in ipairs(hl.get_monitors()) do
    showing[monitor.name] = monitor.active_workspace and monitor.active_workspace.id
  end
  local focused = hl.get_active_monitor()
  focused = focused and focused.name

  local per_screen = math.max(1, math.floor(tonumber(manjikaze_workspaces_per_monitor) or 2))
  for index, screen in ipairs(screens) do
    for round = 0, per_screen - 1 do
      local number = index + round * #screens
      -- SUPER + 1 … 0 reach ten workspaces.
      if number > 10 then
        break
      end
      hl.workspace_rule({ workspace = tostring(number), monitor = screen.output, persistent = true, default = round == 0 })
    end
  end

  -- A screen whose workspace just moved elsewhere shows its own first workspace instead of a
  -- random empty one. Focus goes back to the screen that had it.
  show_timer = hl.timer(function()
    local changed = false
    for index, screen in ipairs(screens) do
      local workspace = showing[screen.name] and hl.get_workspace(showing[screen.name])
      if workspace and workspace.monitor and workspace.monitor.name ~= screen.name then
        hl.dispatch(hl.dsp.focus({ workspace = index }))
        changed = true
      end
    end
    local monitor = changed and focused and hl.get_monitor(focused)
    if monitor and monitor.active_workspace then
      hl.dispatch(hl.dsp.focus({ workspace = monitor.active_workspace.id }))
    end
  end, { timeout = 100, type = "oneshot" })
end

assign_workspaces()

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

-- After login the config is loaded before any screen exists, and screens arrive one at a
-- time, so the workspaces are assigned once they are all there. Unplugging a screen changes
-- the monitor profile, and manjikaze-hypr-monitors reloads the config for that.
local assign_timer
local function assign_workspaces_soon()
  if assign_timer then
    assign_timer:set_enabled(false)
  end
  assign_timer = hl.timer(assign_workspaces, { timeout = 500, type = "oneshot" })
end

hl.on("monitor.added", function(monitor)
  if lid_closed() then
    reload_soon()
  else
    apply_automatic(monitor)
    assign_workspaces_soon()
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
