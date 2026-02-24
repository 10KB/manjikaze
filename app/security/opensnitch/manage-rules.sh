OPENSNITCH_RULES_DIR="/etc/opensnitchd/rules"
OPENSNITCH_CONFIGS_DIR="$MANJIKAZE_DIR/configs/opensnitch"

if ! is_installed "opensnitch"; then
    status "OpenSnitch is not installed. Please install it first."
    return
fi

if [ ! -d "$OPENSNITCH_RULES_DIR" ]; then
    status "OpenSnitch rules directory not found at $OPENSNITCH_RULES_DIR"
    return
fi

# List available application rule sets from configs/opensnitch/
AVAILABLE_APPS=($(ls -d "$OPENSNITCH_CONFIGS_DIR"/*/  2>/dev/null | xargs -n1 basename))

if [ ${#AVAILABLE_APPS[@]} -eq 0 ]; then
    status "No application rule sets found in $OPENSNITCH_CONFIGS_DIR"
    return
fi

# Determine current status for each app (active/inactive)
OPTIONS=()
for app in "${AVAILABLE_APPS[@]}"; do
    # Count rule files for this app
    rule_count=$(ls "$OPENSNITCH_CONFIGS_DIR/$app/"*.json 2>/dev/null | wc -l)

    # Check if rules are currently symlinked (active)
    first_rule=$(ls "$OPENSNITCH_CONFIGS_DIR/$app/"*.json 2>/dev/null | head -1)
    if [ -n "$first_rule" ]; then
        rule_name=$(basename "$first_rule")
        if [ -L "$OPENSNITCH_RULES_DIR/$rule_name" ]; then
            OPTIONS+=("$app ($rule_count rules, active)")
        else
            OPTIONS+=("$app ($rule_count rules, inactive)")
        fi
    fi
done

ACTION=$(gum choose "Activate rules" "Deactivate rules" "Show status" --header "OpenSnitch Firewall Rules")

case "$ACTION" in
    "Activate rules")
        # Show only inactive apps
        INACTIVE_APPS=()
        for app in "${AVAILABLE_APPS[@]}"; do
            first_rule=$(ls "$OPENSNITCH_CONFIGS_DIR/$app/"*.json 2>/dev/null | head -1)
            if [ -n "$first_rule" ]; then
                rule_name=$(basename "$first_rule")
                if [ ! -L "$OPENSNITCH_RULES_DIR/$rule_name" ]; then
                    INACTIVE_APPS+=("$app")
                fi
            fi
        done

        if [ ${#INACTIVE_APPS[@]} -eq 0 ]; then
            status "All application rules are already active."
            return
        fi

        SELECTED=$(gum choose "${INACTIVE_APPS[@]}" --no-limit --height 20 --header "Select applications to activate firewall rules for")

        if [ -z "$SELECTED" ]; then
            status "No applications selected."
            return
        fi

        for app in $SELECTED; do
            status "Activating rules for $app..."
            for rule_file in "$OPENSNITCH_CONFIGS_DIR/$app/"*.json; do
                rule_name=$(basename "$rule_file")
                sudo ln -sf "$rule_file" "$OPENSNITCH_RULES_DIR/$rule_name"
                status "  Linked $rule_name"
            done
        done
        status "Restarting OpenSnitch daemon to load new rules..."
        sudo systemctl restart opensnitchd.service
        status "Rules activated."
        ;;

    "Deactivate rules")
        # Show only active apps
        ACTIVE_APPS=()
        for app in "${AVAILABLE_APPS[@]}"; do
            first_rule=$(ls "$OPENSNITCH_CONFIGS_DIR/$app/"*.json 2>/dev/null | head -1)
            if [ -n "$first_rule" ]; then
                rule_name=$(basename "$first_rule")
                if [ -L "$OPENSNITCH_RULES_DIR/$rule_name" ]; then
                    ACTIVE_APPS+=("$app")
                fi
            fi
        done

        if [ ${#ACTIVE_APPS[@]} -eq 0 ]; then
            status "No application rules are currently active."
            return
        fi

        SELECTED=$(gum choose "${ACTIVE_APPS[@]}" --no-limit --height 20 --header "Select applications to deactivate firewall rules for")

        if [ -z "$SELECTED" ]; then
            status "No applications selected."
            return
        fi

        for app in $SELECTED; do
            status "Deactivating rules for $app..."
            for rule_file in "$OPENSNITCH_CONFIGS_DIR/$app/"*.json; do
                rule_name=$(basename "$rule_file")
                if [ -L "$OPENSNITCH_RULES_DIR/$rule_name" ]; then
                    sudo rm "$OPENSNITCH_RULES_DIR/$rule_name"
                    status "  Removed $rule_name"
                fi
            done
        done
        status "Restarting OpenSnitch daemon to apply changes..."
        sudo systemctl restart opensnitchd.service
        status "Rules deactivated."
        ;;

    "Show status")
        echo ""
        gum style --border normal --padding "0 1" --border-foreground 212 "OpenSnitch Firewall Rules Status"
        echo ""
        for app in "${AVAILABLE_APPS[@]}"; do
            rule_count=$(ls "$OPENSNITCH_CONFIGS_DIR/$app/"*.json 2>/dev/null | wc -l)
            first_rule=$(ls "$OPENSNITCH_CONFIGS_DIR/$app/"*.json 2>/dev/null | head -1)
            if [ -n "$first_rule" ]; then
                rule_name=$(basename "$first_rule")
                if [ -L "$OPENSNITCH_RULES_DIR/$rule_name" ]; then
                    gum style --foreground 2 "  ✓ $app ($rule_count rules, active)"
                else
                    gum style --foreground 1 "  ✗ $app ($rule_count rules, inactive)"
                fi
            fi
        done
        echo ""

        # Show any unmanaged rules in /etc/opensnitchd/rules/
        UNMANAGED=0
        for rule_file in "$OPENSNITCH_RULES_DIR"/*.json; do
            [ -f "$rule_file" ] || continue
            if [ ! -L "$rule_file" ]; then
                if [ $UNMANAGED -eq 0 ]; then
                    echo ""
                    gum style --foreground 3 "  Unmanaged rules (not from manjikaze):"
                fi
                UNMANAGED=$((UNMANAGED + 1))
                gum style --foreground 3 "    - $(basename "$rule_file")"
            fi
        done
        if [ $UNMANAGED -gt 0 ]; then
            echo ""
            gum style --foreground 3 "  $UNMANAGED unmanaged rule(s) found."
            gum style --faint "  These were created manually via the OpenSnitch UI."
        fi
        ;;
esac
