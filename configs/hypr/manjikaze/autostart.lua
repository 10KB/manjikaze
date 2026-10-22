-- Bar, notifications, launcher, OSD, idle/lock, wallpaper, polkit and the monitor profile
-- daemon are systemd user units pulled in by manjikaze-hyprland.target. Only Hyprland starts
-- that target, so none of them run inside a GNOME session. Tray applets (network, bluetooth)
-- come from XDG autostart, which uwsm runs for the Hyprland session.

hl.on("hyprland.start", function()
  hl.exec_cmd("systemctl --user start manjikaze-hyprland.target")
end)
