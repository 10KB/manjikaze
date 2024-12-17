configure_printing() {
    setup_printing=$(gum confirm "Do you want to enable network printer discovery?" --affirmative "Yes" --negative "No" --default=false && echo "true" || echo "false")

    if [[ $setup_printing == "true" ]]; then
        status "Enabling network printer discovery service..."

        sudo systemctl enable --now avahi-daemon.service

        status "Network printer discovery service enabled."
    fi
}