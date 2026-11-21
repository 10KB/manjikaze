source "$MANJIKAZE_DIR/app/security/browser/browser-policies.sh"

# New installations get the policies with the essential apps, existing ones through a migration.
install() {
    apply_browser_policies || status "The browser policies were not fully applied. Fix the error above and choose Security > Apply browser policies."
}

uninstall() {
    remove_browser_policies || status "Not all browser policies were removed. See the error above."
}
