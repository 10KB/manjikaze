-- The session services are systemd user units in configs/systemd/user, pulled in by
-- manjikaze-hyprland.target. Only Hyprland starts that target, so none of them run inside a
-- GNOME session.

hl.on("hyprland.start", function()
  hl.exec_cmd("systemctl --user start manjikaze-hyprland.target")
end)
