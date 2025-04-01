#!/bin/bash

status() {
    time=$(date +%T)
    echo -e "\033[1;32m$time\033[0m - \033[0;32m$1\033[0m"
}


# Version management
get_version() {
    git -C "$MANJIKAZE_DIR" describe --tags 2>/dev/null || echo "dev"
}

# Check if a package is installed using pamac
is_installed() {
    # Run pamac info, suppress stderr for 'target not found' errors
    # Check exit code AND presence of 'Install Date' line
    if pamac info "$1" 2>/dev/null | grep -q "Install Date"; then
        return 0 # Package found and install date exists - Installed
    else
        return 1 # Package not found OR install date missing - Not installed
    fi
}

# Install package using pamac (handles repo and AUR)
# Usage: install_package <package_name> [aur]
install_package() {
    local package=$1
    local type=${2:-repo} # Default to repo
    local cmd

    # Check if already installed
    if is_installed "$package"; then
        status "Package '$package' is already installed. Skipping."
        return 0
    fi

    if [[ "$type" == "aur" ]]; then
        status "Installing AUR package $package..."
        cmd="sudo pamac build --no-confirm $package"
    else
        status "Installing repository package $package..."
        cmd="sudo pamac install --no-confirm $package"
    fi

    # Execute the command. We already know it's not installed.
    # Capture output to prevent excessive install logs unless there's an error.
    output=$($cmd 2>&1)
    if [[ $? -ne 0 ]]; then
        status "Error installing $package:"
        echo "$output" # Show output only on error
        return 1 # Indicate failure
    else
        status "Package '$package' installed successfully."
    fi
}

MIGRATIONS_DIR="$MANJIKAZE_DIR/migrations"
MIGRATIONS_LOG_FILE="$MANJIKAZE_DIR/.migrations_log.json"

run_migrations() {
    if [[ ! -d "$MIGRATIONS_DIR" ]]; then
        status "Migrations directory not found. Skipping migrations."
        return 0
    fi

    # Find migration scripts, sort by name (timestamp)
    readarray -t migration_files < <(find "$MIGRATIONS_DIR" -maxdepth 1 -name '*.sh' -print0 | xargs -0 -n1 basename | sort)

    if [[ ${#migration_files[@]} -eq 0 ]]; then
        return 0 # No migrations to run
    fi

    if [[ ! -f "$MIGRATIONS_LOG_FILE" ]]; then
        echo "{}" > "$MIGRATIONS_LOG_FILE"
    fi

    local pending_migrations=()
    for migration_file in "${migration_files[@]}"; do
        local migration_id="${migration_file%.sh}"
        # Check if migration_id key exists in the JSON log
        if ! jq -e ".\"$migration_id\"" "$MIGRATIONS_LOG_FILE" > /dev/null; then
            pending_migrations+=("$migration_file")
        fi
    done

    if [[ ${#pending_migrations[@]} -eq 0 ]]; then
        return 0 # All migrations are up to date
    fi

    status "Found ${#pending_migrations[@]} pending migration(s):"
    printf "  - %s\n" "${pending_migrations[@]}"

    if ! gum confirm "Do you want to run pending migrations?"; then
        return 1 # User cancelled
    fi

    for migration_file in "${pending_migrations[@]}"; do
        local migration_id="${migration_file%.sh}"
        local migration_path="$MIGRATIONS_DIR/$migration_file"

        status "Running migration: $migration_file ..."
        # Source the migration script. It should exit on error due to set -e.
        if source "$migration_path"; then
            # Record successful migration with timestamp
            local run_timestamp=$(date --iso-8601=seconds)
            local temp_log=$(mktemp)
            jq --arg id "$migration_id" --arg ts "$run_timestamp" '. + {($id): $ts}' "$MIGRATIONS_LOG_FILE" > "$temp_log" && mv "$temp_log" "$MIGRATIONS_LOG_FILE"
            if [[ $? -ne 0 ]]; then
                 status "Error: Failed to update migration log for $migration_id. Manual check required."
                 # Even though logging failed, the migration ran. Avoid retrying automatically.
            fi
             status "Migration $migration_file completed successfully."
        else
            local exit_code=$?
            status "Error: Migration $migration_file failed with exit code $exit_code. Halting migration process."
            return $exit_code # Stop processing further migrations on failure
        fi
    done

    status "All pending migrations processed."
}


sudo -v -p "We need sudo permissions for the installation process. Please enter your password: "

# Keep sudo alive
while true; do sudo -n true; sleep 3600; kill -0 "$$" || exit; done 2>/dev/null &
