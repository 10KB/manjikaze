-- Prints the hl.monitor() rules of a Hyprland Lua file (as written by nwg-displays) as JSON.
-- The file runs in a sandbox where only hl.monitor exists; anything else is ignored.
-- Usage: lua monitor-rules-to-json.lua ~/.config/hypr/monitors.lua

local rules = {}

local ignore = setmetatable({}, {
  __index = function()
    return function() end
  end,
})

local hl = setmetatable({
  monitor = function(rule)
    if type(rule) == "table" then
      table.insert(rules, rule)
    end
  end,
}, { __index = ignore })

local chunk = loadfile(arg[1], "t", { hl = hl })
if not chunk then
  io.write("[]\n")
  return
end
pcall(chunk)

local function encode_string(value)
  return '"' .. value:gsub('[%c"\\]', function(c)
    return string.format("\\u%04x", c:byte())
  end) .. '"'
end

local function encode_value(value)
  local kind = type(value)
  if kind == "string" then
    return encode_string(value)
  elseif kind == "number" then
    if value ~= value or value == math.huge or value == -math.huge then
      return "null"
    end
    return string.format("%.10g", value)
  elseif kind == "boolean" then
    return tostring(value)
  end
  return "null"
end

local out = {}
for _, rule in ipairs(rules) do
  local fields = {}
  for key, value in pairs(rule) do
    if type(key) == "string" and type(value) ~= "table" and type(value) ~= "function" then
      table.insert(fields, encode_string(key) .. ":" .. encode_value(value))
    end
  end
  table.sort(fields)
  table.insert(out, "{" .. table.concat(fields, ",") .. "}")
end

io.write("[" .. table.concat(out, ",") .. "]\n")
