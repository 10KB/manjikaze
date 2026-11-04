-- Makes Manjikaze's Hyprland modules requireable from ~/.config/hypr/hyprland.lua.
-- Every reload starts a fresh Lua state, so nothing set here survives between reloads.

local this_file = debug.getinfo(1, "S").source:gsub("^@", "")
local configs_dir = this_file:match("^(.*)/bootstrap%.lua$")

local search = configs_dir .. "/?.lua;" .. configs_dir .. "/?/init.lua;"
if not package.path:find(search, 1, true) then
  package.path = search .. package.path
end

local function env_or(name, fallback)
  local value = os.getenv(name)
  if value == nil or value == "" then
    return fallback
  end
  return value
end

local home = os.getenv("HOME")
local manjikaze_dir = configs_dir:gsub("/configs/hypr$", "")

manjikaze = {
  dir = manjikaze_dir,
  bin = manjikaze_dir .. "/bin/hypr",
  home = home,
  config_home = env_or("XDG_CONFIG_HOME", home .. "/.config"),
  state_home = env_or("XDG_STATE_HOME", home .. "/.local/state"),
}
