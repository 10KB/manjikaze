#!/bin/bash

AUDITS_DIR="$MANJIKAZE_DIR/audits"

run_audits() {
    if [[ ! -d "$AUDITS_DIR" ]]; then
        status "Audits directory not found. Skipping audits."
        return 0
    fi

    # Find audit scripts, sort by name
    readarray -t audit_files < <(find "$AUDITS_DIR" -maxdepth 1 -name '*.sh' -print0 | xargs -0 -n1 basename | sort)

    if [[ ${#audit_files[@]} -eq 0 ]]; then
        return 0 # No audits to run
    fi

    local pending_audits=()
    for audit_file in "${audit_files[@]}"; do
        local audit_id="${audit_file%.sh}"
        # Check if audit has been passed
        if [[ "$(get_audit_state "$audit_id")" == "" ]]; then
            pending_audits+=("$audit_file")
        fi
    done

    if [[ ${#pending_audits[@]} -eq 0 ]]; then
        return 0 # All audits have passed
    fi

    status "Found ${#pending_audits[@]} pending audit(s):"
    printf "  - %s\n" "${pending_audits[@]}"

    if ! gum confirm "Do you want to run pending audits?"; then
        return 1 # User cancelled
    fi

    local failed_audits=()
    for audit_file in "${pending_audits[@]}"; do
        local audit_id="${audit_file%.sh}"
        local audit_path="$AUDITS_DIR/$audit_file"
        local audit_name=$(grep -m 1 "^# " "$audit_path" 2>/dev/null | sed 's/^# //' || echo "$audit_id")

        status "Running audit: $audit_name ..."

        # Create a temporary script that sources our environment and runs the audit
        local temp_script=$(mktemp)

        cat > "$temp_script" << EOF
#!/bin/bash
# Sourcing required functions and variables
export MANJIKAZE_DIR="$MANJIKAZE_DIR"
source "$MANJIKAZE_DIR/lib/common.sh"
source "$MANJIKAZE_DIR/lib/state.sh"

# Set up trap for interrupts
trap 'echo -e "\nAudit interrupted by user"; exit 1' INT

# Run the actual audit
source "$audit_path"
EOF

        chmod +x "$temp_script"

        # Run the temporary script
        "$temp_script"
        local exit_code=$?

        # Clean up
        rm "$temp_script"

        # Handle exit codes
        if [[ $exit_code -eq 130 || $exit_code -eq 131 ]]; then
            status "Audit $audit_name was interrupted."
            return 1
        elif [[ $exit_code -eq 0 ]]; then
            # Record successful audit with timestamp
            local passed_timestamp=$(date --iso-8601=seconds)
            set_audit_state "$audit_id" "$passed_timestamp"
            if [[ $? -ne 0 ]]; then
                status "Error: Failed to update audit log for $audit_id. Manual check required."
            fi
            status "Audit $audit_name passed successfully."
        else
            status "Audit $audit_name failed with exit code $exit_code. It will be run again next time."
            failed_audits+=("$audit_file")
        fi
    done

    # Give the user time to see the results
    if [[ ${#failed_audits[@]} -gt 0 ]]; then
        status "${#failed_audits[@]} audit(s) failed and will be checked again next time."
        echo ""
        gum input --prompt "Press Enter to continue... "
        return 1
    else
        status "All audits passed successfully."
        echo ""
        gum input --prompt "Press Enter to continue... "
        return 0
    fi
}
