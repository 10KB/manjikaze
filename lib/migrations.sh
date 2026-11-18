#!/bin/bash

MIGRATIONS_DIR="$MANJIKAZE_DIR/migrations"

# Migration ids in the order they run: file names without .sh, which start with a timestamp.
list_migrations() {
    local file
    for file in "$MIGRATIONS_DIR"/*.sh; do
        if [[ -f "$file" ]]; then
            basename "$file" .sh
        fi
    done
}

pending_migrations() {
    local migration_id
    while read -r migration_id; do
        if [[ -z "$(get_migration_state "$migration_id")" ]]; then
            echo "$migration_id"
        fi
    done < <(list_migrations)
}

# A new installation already has what earlier migrations changed, so they are recorded
# without running. Call this after setup_package_install, which may copy an earlier state file.
mark_migrations_done_on_new_install() {
    if [[ -f "$STATE_FILE" ]]; then
        return 0
    fi

    # Written without jq: check_prerequisites installs it later. The migrations check keeps
    # migration ids to lowercase letters, digits and underscores, so they need no escaping.
    local migration_id timestamp entries=()
    timestamp=$(date --iso-8601=seconds)
    while read -r migration_id; do
        entries+=("\"$migration_id\": \"$timestamp\"")
    done < <(list_migrations)

    mkdir -p "$MANJIKAZE_DATA_DIR"
    printf '{"migrations": {%s}, "audits": {}, "updates": {}}\n' "$(IFS=,; echo "${entries[*]}")" > "$STATE_FILE.tmp"
    mv "$STATE_FILE.tmp" "$STATE_FILE"
}

# Each migration runs in a process of its own, so an exit in it can't stop Manjikaze.
# The migration is sourced there, which lets it end early with return.
run_migration() {
    bash -c '
        set -e
        source "$MANJIKAZE_DIR/lib/common.sh"
        source "$MANJIKAZE_DIR/lib/state.sh"
        migration_path=$1
        shift
        source "$migration_path"
    ' manjikaze-migration "$1"
}

# Asks before running the pending migrations, unless called with --yes.
run_migrations() {
    local pending_migrations
    readarray -t pending_migrations < <(pending_migrations)

    if [[ ${#pending_migrations[@]} -eq 0 ]]; then
        return 0
    fi

    status "Found ${#pending_migrations[@]} pending migration(s):"
    printf "  - %s\n" "${pending_migrations[@]}"

    if [[ "${1:-}" != "--yes" ]] && ! gum confirm "Do you want to run pending migrations?"; then
        return 1
    fi

    local migration_id exit_code
    for migration_id in "${pending_migrations[@]}"; do
        status "Running migration: $migration_id ..."
        if run_migration "$MIGRATIONS_DIR/$migration_id.sh"; then
            set_migration_state "$migration_id" "$(date --iso-8601=seconds)"
            status "Migration $migration_id completed successfully."
        else
            exit_code=$?
            status "Error: Migration $migration_id failed with exit code $exit_code. Halting migration process."
            return "$exit_code"
        fi
    done

    status "All pending migrations processed."
}
