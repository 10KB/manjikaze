#!/bin/bash
# Running migrations, listing the pending ones, and recording them on a new installation.
set -euo pipefail

source "$(dirname "$0")/lib.sh"

MANJIKAZE="$TEST_TMP/manjikaze"
STATE="$MANJIKAZE/.manjikaze_state.json"

# A development checkout with only the given migrations and no state file.
new_manjikaze() {
    rm -rf "$MANJIKAZE" "$HOME" "$TEST_TMP"/ran-* "$TEST_TMP"/*.calls
    mkdir -p "$MANJIKAZE/bin" "$MANJIKAZE/migrations" "$HOME"
    cp "$ROOT/bin/manjikaze" "$MANJIKAZE/bin/"
    cp -r "$ROOT/lib" "$MANJIKAZE/"
}

add_migration() {
    printf '#!/bin/bash\nset -e\n\n%s\n' "$2" > "$MANJIKAZE/migrations/$1.sh"
}

# Records the given migrations as done.
write_state() {
    local file=$1 migration_id
    shift
    mkdir -p "$(dirname "$file")"
    echo '{"migrations": {}, "audits": {}, "updates": {}}' > "$file"
    for migration_id in "$@"; do
        jq --arg id "$migration_id" '.migrations[$id] = "2026-01-01T00:00:00+01:00"' "$file" > "$file.tmp"
        mv "$file.tmp" "$file"
    done
}

recorded() {
    jq -e --arg id "$1" '.migrations[$id] // empty' "$STATE" > /dev/null
}

new_manjikaze
write_state "$STATE"
add_migration 1000000001_exits 'touch "$TEST_TMP/ran-1"; exit 0'
add_migration 1000000002_after_exit 'touch "$TEST_TMP/ran-2"'
run "$MANJIKAZE/bin/manjikaze" migrate
[[ $exit_code -eq 0 ]] || fail "migrate succeeds when a migration exits with 0" "$(errors)"
[[ -f $TEST_TMP/ran-2 ]] || fail "an exit in a migration does not stop the migrations after it" "$(errors)"
recorded 1000000001_exits && recorded 1000000002_after_exit || fail "both migrations are recorded" "$(cat "$STATE")"
pass "an exit in a migration ends only that migration"

new_manjikaze
write_state "$STATE"
add_migration 1000000001_returns 'status "helpers are loaded"
[[ -n $STATE_FILE ]]
return 0
touch "$TEST_TMP/ran-after-return"'
run "$MANJIKAZE/bin/manjikaze" migrate
[[ $exit_code -eq 0 ]] || fail "migrate succeeds when a migration returns 0" "$(errors)"
grep -q "helpers are loaded" "$TEST_TMP/err" || fail "a migration can use the status helper" "$(errors)"
[[ ! -e $TEST_TMP/ran-after-return ]] || fail "return ends the migration"
recorded 1000000001_returns || fail "a migration that returns early is recorded" "$(cat "$STATE")"
pass "a migration can use Manjikaze's helpers and end early with return"

new_manjikaze
write_state "$STATE"
add_migration 1000000001_fails 'false'
add_migration 1000000002_after_failure 'touch "$TEST_TMP/ran-2"'
run "$MANJIKAZE/bin/manjikaze" migrate
[[ $exit_code -ne 0 ]] || fail "migrate fails when a migration fails"
grep -q "Migration 1000000001_fails failed" "$TEST_TMP/err" || fail "the failed migration is named" "$(errors)"
[[ ! -e $TEST_TMP/ran-2 ]] || fail "the migrations after a failure don't run"
! recorded 1000000001_fails || fail "a failed migration is not recorded"
pass "a failing migration halts the run and is not recorded"

new_manjikaze
write_state "$STATE" 1000000001_done
add_migration 1000000001_done 'touch "$TEST_TMP/ran-1"'
add_migration 1000000002_pending 'touch "$TEST_TMP/ran-2"'
add_migration 1000000003_pending 'touch "$TEST_TMP/ran-3"'
run "$MANJIKAZE/bin/manjikaze" migrate --pending
[[ $exit_code -eq 0 ]] || fail "migrate --pending exits 0 when migrations are pending" "$(errors)"
[[ $(output) == $'1000000002_pending\n1000000003_pending' ]] || fail "migrate --pending prints the pending migrations in order" "$(output)"
[[ ! -e $TEST_TMP/sudo.calls ]] || fail "migrate --pending does not ask for sudo"
! compgen -G "$TEST_TMP/ran-*" > /dev/null || fail "migrate --pending runs no migrations"
write_state "$STATE" 1000000001_done 1000000002_pending 1000000003_pending
run "$MANJIKAZE/bin/manjikaze" migrate --pending
[[ $exit_code -eq 1 && -z $(output) ]] || fail "migrate --pending prints nothing and exits 1 without pending migrations" "code $exit_code: $(output)"
pass "migrate --pending lists pending migrations without running them"

new_manjikaze
add_migration 1000000001_earlier 'touch "$TEST_TMP/ran-1"'
add_migration 1000000002_earlier 'touch "$TEST_TMP/ran-2"'
run "$MANJIKAZE/bin/manjikaze" migrate --pending
[[ $exit_code -eq 1 ]] || fail "a new installation has no pending migrations" "$(output)$(errors)"
! compgen -G "$TEST_TMP/ran-*" > /dev/null || fail "a new installation does not run earlier migrations"
recorded 1000000001_earlier && recorded 1000000002_earlier || fail "a new installation records earlier migrations" "$(cat "$STATE")"
add_migration 1000000003_later 'touch "$TEST_TMP/ran-3"'
run "$MANJIKAZE/bin/manjikaze" migrate --pending
[[ $(output) == 1000000003_later ]] || fail "a migration added after the installation is pending" "$(output)"
pass "a new installation records earlier migrations without running them"

new_manjikaze
echo "1.0.0" > "$MANJIKAZE/VERSION"
write_state "$HOME/.manjikaze/.manjikaze_state.json" 1000000001_done
add_migration 1000000001_done 'touch "$TEST_TMP/ran-1"'
add_migration 1000000002_pending 'touch "$TEST_TMP/ran-2"'
run "$MANJIKAZE/bin/manjikaze" migrate --pending
[[ $(output) == 1000000002_pending ]] || fail "a package install keeps the git install's pending migrations" "$(output)$(errors)"
pass "a package install takes over the git install's state instead of recording every migration"

# The notice after login: notify-send prints the action that was clicked, and the terminal records
# what it was asked to run.
cat > "$TEST_TMP/bin/notify-send" << 'EOF'
#!/bin/bash
echo "$*" >> "$TEST_TMP/notify-send.calls"
echo "${NOTIFY_ACTION:-}"
EOF
cat > "$TEST_TMP/bin/alacritty" << 'EOF'
#!/bin/bash
echo "$*" >> "$TEST_TMP/alacritty.calls"
EOF
printf '#!/bin/bash\n' > "$TEST_TMP/bin/gdbus"
chmod +x "$TEST_TMP/bin/notify-send" "$TEST_TMP/bin/alacritty" "$TEST_TMP/bin/gdbus"

new_manjikaze
write_state "$STATE" 1000000001_done
add_migration 1000000001_done 'touch "$TEST_TMP/ran-1"'
add_migration 1000000002_pending 'touch "$TEST_TMP/ran-2"'
add_migration 1000000003_pending 'touch "$TEST_TMP/ran-3"'
export NOTIFY_ACTION=migrate
run "$MANJIKAZE/bin/manjikaze" migrate --notify
[[ $exit_code -eq 0 ]] || fail "migrate --notify succeeds" "$(errors)"
grep -q "2 migration(s) are waiting" "$TEST_TMP/notify-send.calls" || fail "the notice says how many migrations are waiting" "$(cat "$TEST_TMP/notify-send.calls" 2>&1)"
grep -q -- "--urgency=critical" "$TEST_TMP/notify-send.calls" || fail "the notice stays until it is closed"
grep -q "$MANJIKAZE/bin/manjikaze migrate$" "$TEST_TMP/alacritty.calls" || fail "the button opens a terminal that runs manjikaze migrate" "$(cat "$TEST_TMP/alacritty.calls" 2>&1)"
! compgen -G "$TEST_TMP/ran-*" > /dev/null || fail "the notice runs no migrations by itself"
[[ ! -e $TEST_TMP/sudo.calls ]] || fail "the notice doesn't ask for sudo"
export NOTIFY_ACTION=""
rm -f "$TEST_TMP/alacritty.calls"
run "$MANJIKAZE/bin/manjikaze" migrate --notify
[[ ! -e $TEST_TMP/alacritty.calls ]] || fail "closing the notice opens no terminal"
pass "migrate --notify shows the pending migrations with a button that applies them"

new_manjikaze
write_state "$STATE" 1000000001_done
add_migration 1000000001_done 'touch "$TEST_TMP/ran-1"'
run "$MANJIKAZE/bin/manjikaze" migrate --notify
[[ $exit_code -eq 0 ]] || fail "migrate --notify succeeds without pending migrations" "$(errors)"
[[ ! -e $TEST_TMP/notify-send.calls ]] || fail "without pending migrations there is no notice"
pass "migrate --notify stays quiet without pending migrations"
