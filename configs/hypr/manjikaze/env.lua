-- Session-wide variables (toolkits, cursor, NVIDIA) live in ~/.config/uwsm/env so systemd
-- services see them too. Only what Hyprland's own children need is set here.

local bin = manjikaze.bin
local kept = { bin }
for entry in (os.getenv("PATH") or "/usr/local/bin:/usr/bin"):gmatch("[^:]+") do
  if entry ~= bin then
    table.insert(kept, entry)
  end
end

hl.env("PATH", table.concat(kept, ":"))
hl.env("MANJIKAZE_DIR", manjikaze.dir)

hl.config({
  xwayland = {
    force_zero_scaling = true,
  },

  ecosystem = {
    no_update_news = true,
    no_donation_nag = true,
  },
})
