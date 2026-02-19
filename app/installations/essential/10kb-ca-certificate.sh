install() {
    if [ -f "$MANJIKAZE_DIR/assets/certs/10kb-root-ca.crt" ]; then
        sudo cp "$MANJIKAZE_DIR/assets/certs/10kb-root-ca.crt" "/etc/ca-certificates/trust-source/anchors/10kb-root-ca.crt"
        sudo update-ca-trust
    else
        echo "Root CA certificaat niet gevonden in repo assets/certs/!"
    fi
}

uninstall() {
    sudo rm -f "/etc/ca-certificates/trust-source/anchors/10kb-root-ca.crt"
    sudo update-ca-trust
}
