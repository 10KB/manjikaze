for installer in ./install/desktop/*.sh; do source $installer; done

gum confirm "Ready to logout for all settings to take effect?" && gnome-session-quit --logout --no-prompt
