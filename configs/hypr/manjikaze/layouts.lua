-- Tiling (dwindle) or scrolling per workspace, toggled with SUPER + ALT + L. Every reload
-- (saving a config file, plugging in a screen) starts a fresh Lua state and drops runtime
-- workspace rules, so the choice is kept in ~/.local/state and restored here.

local helpers = require("manjikaze.helpers")

local state_dir = manjikaze.state_home .. "/manjikaze/hypr"
local state_file = state_dir .. "/workspace-layouts.lua"

local M = {}

local function load()
  if not helpers.file_exists(state_file) then
    return {}
  end
  local ok, saved = pcall(dofile, state_file)
  if ok and type(saved) == "table" then
    return saved
  end
  return {}
end

local layouts = load()

local function save()
  local names = {}
  for name in pairs(layouts) do
    table.insert(names, name)
  end
  table.sort(names)

  local lines = { "-- Written by SUPER + ALT + L (manjikaze/layouts.lua).", "return {" }
  for _, name in ipairs(names) do
    table.insert(lines, string.format("  [%q] = %q,", name, layouts[name]))
  end
  table.insert(lines, "}")

  local file = io.open(state_file, "w")
  if not file then
    os.execute("mkdir -p " .. helpers.shell_quote(state_dir))
    file = io.open(state_file, "w")
  end
  if file then
    file:write(table.concat(lines, "\n") .. "\n")
    file:close()
  end
end

for name, layout in pairs(layouts) do
  if type(name) == "string" and (layout == "dwindle" or layout == "scrolling") then
    hl.workspace_rule({ workspace = name, layout = layout })
  end
end

function M.toggle()
  local workspace = hl.get_active_workspace()
  if not workspace or workspace.special then
    return
  end

  local layout = workspace.tiled_layout == "scrolling" and "dwindle" or "scrolling"
  layouts[workspace.name] = layout
  save()
  hl.workspace_rule({ workspace = workspace.name, layout = layout })

  local label = layout == "scrolling" and "Scrolling" or "Tiling"
  hl.exec_cmd("notify-send --app-name Hyprland --expire-time 1500 "
    .. "--hint string:x-canonical-private-synchronous:manjikaze-layout "
    .. helpers.shell_quote(label .. " layout on workspace " .. workspace.name))
end

return M
