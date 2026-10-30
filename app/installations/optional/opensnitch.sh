install() {
    install_package "opensnitch" repo

    sudo systemctl enable --now opensnitchd

    mkdir -p ~/.config/autostart/
    cp /usr/share/applications/opensnitch_ui.desktop ~/.config/autostart/

    # The prompt preselects "12h", a rule that is gone after a restart. In 1.7,
    # index 8 is "forever".
    if [[ ! -f ~/.config/opensnitch/settings.conf && "$(pacman -Q opensnitch | awk '{print $2}')" == 1.7.* ]]; then
        mkdir -p ~/.config/opensnitch
        printf '[global]\ndefault_duration=8\n' > ~/.config/opensnitch/settings.conf
    fi
}

uninstall() {
    sudo systemctl disable --now opensnitchd

    rm -f ~/.config/autostart/opensnitch_ui.desktop

    uninstall_package "opensnitch" repo
}
