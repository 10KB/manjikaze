# Arch's scaleway-cli lags months behind upstream, so scw comes from mise.
install() {
    install_mise_tool scaleway
}

uninstall() {
    uninstall_mise_tool scaleway
}
