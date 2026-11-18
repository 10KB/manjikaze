#!/bin/bash

# Machine policies apply to every browser profile and can't be changed in the browser's settings.
# Chromium-based browsers read every JSON file in their managed directory, so Manjikaze adds its own
# files next to any others. Firefox reads a single policies.json, so Manjikaze merges into that file.
# The directories are created even when a browser isn't installed, so a browser installed later
# starts with the policies.
BROWSER_POLICIES_SOURCE="$MANJIKAZE_DIR/configs/browser-policies"
BROWSER_POLICIES_CHROMIUM_DIRS=(
    /etc/opt/chrome/policies/managed
    /etc/chromium/policies/managed
    /etc/brave/policies/managed
)
BROWSER_POLICIES_BRAVE_DIR=/etc/brave/policies/managed
BROWSER_POLICIES_FIREFOX_FILE=/etc/firefox/policies/policies.json

browser_policies_install_chromium() {
    local dir
    for dir in "${BROWSER_POLICIES_CHROMIUM_DIRS[@]}"; do
        sudo install -d -m 755 "$dir" || return 1
        sudo install -m 644 "$BROWSER_POLICIES_SOURCE/chromium.json" "$dir/manjikaze.json" || return 1
    done
    sudo install -m 644 "$BROWSER_POLICIES_SOURCE/brave.json" "$BROWSER_POLICIES_BRAVE_DIR/manjikaze-brave.json" || return 1
}

# Policies already in policies.json stay; for a policy Manjikaze also sets, Manjikaze's value wins.
browser_policies_install_firefox() {
    local merged result=0
    merged=$(mktemp) || return 1

    if [[ -f $BROWSER_POLICIES_FIREFOX_FILE ]]; then
        if ! jq -s '.[0] * .[1]' "$BROWSER_POLICIES_FIREFOX_FILE" "$BROWSER_POLICIES_SOURCE/firefox.json" >"$merged"; then
            status "$BROWSER_POLICIES_FIREFOX_FILE is not valid JSON, so it was left unchanged."
            rm -f "$merged"
            return 1
        fi
    elif ! cp "$BROWSER_POLICIES_SOURCE/firefox.json" "$merged"; then
        rm -f "$merged"
        return 1
    fi

    if ! sudo install -d -m 755 "$(dirname "$BROWSER_POLICIES_FIREFOX_FILE")" ||
        ! sudo install -m 644 "$merged" "$BROWSER_POLICIES_FIREFOX_FILE"; then
        result=1
    fi
    rm -f "$merged"
    return "$result"
}

apply_browser_policies() {
    status "Applying browser policies for Chrome, Chromium and Brave..."
    if ! browser_policies_install_chromium; then
        status "Failed to apply the policies for Chrome, Chromium and Brave."
        return 1
    fi

    status "Applying browser policies for Firefox..."
    if ! browser_policies_install_firefox; then
        status "Failed to apply the policies for Firefox."
        return 1
    fi

    status "Browser policies applied. Restart open browsers to load them."
}
