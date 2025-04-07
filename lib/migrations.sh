#!/bin/bash

MIGRATIONS_DIR="$MANJIKAZE_DIR/migrations"

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

    local pending_migrations=()
    for migration_file in "${migration_files[@]}"; do
        local migration_id="${migration_file%.sh}"
        # Check if migration has been run using the new state management
        if [[ "$(get_migration_state "$migration_id")" == "" ]]; then
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
            set_migration_state "$migration_id" "$run_timestamp"
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
