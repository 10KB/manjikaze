-- Shared helpers for Manjikaze's Hyprland modules.

local M = {}

function M.file_exists(path)
  local file = io.open(path, "r")
  if file then
    file:close()
    return true
  end
  return false
end

function M.read_file(path)
  local file = io.open(path, "r")
  if not file then
    return nil
  end
  local content = file:read("*a")
  file:close()
  return content
end

function M.cmd_present(command)
  for directory in ((os.getenv("PATH") or "/usr/local/bin:/usr/bin") .. ":"):gmatch("([^:]*):") do
    if directory ~= "" and M.file_exists(directory .. "/" .. command) then
      return true
    end
  end
  return false
end

function M.first_present(...)
  for _, command in ipairs({ ... }) do
    if M.cmd_present(command) then
      return command
    end
  end
  return nil
end

function M.shell_quote(value)
  return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

-- Apps run as their own systemd unit under uwsm instead of as children of Hyprland.
function M.launch(command)
  return "uwsm-app -- " .. command
end

function M.script(name)
  return manjikaze.bin .. "/" .. name
end

-- hl.bind with the description up front, so `hyprctl binds` and the cheatsheet can show it.
function M.bind(keys, description, action, opts)
  opts = opts or {}
  opts.description = description
  if type(action) == "string" then
    action = hl.dsp.exec_cmd(action)
  end
  return hl.bind(keys, action, opts)
end

-- Focus the first window whose class matches the Lua pattern, otherwise launch the app.
function M.launch_or_focus(class_pattern, command)
  return function()
    for _, window in ipairs(hl.get_windows()) do
      local class = (window.class or ""):lower()
      if class:find(class_pattern) then
        hl.dispatch(hl.dsp.focus({ window = window }))
        return
      end
    end
    hl.exec_cmd(M.launch(command))
  end
end

return M
