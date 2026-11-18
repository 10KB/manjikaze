#!/bin/bash
# The order of the system update, and what stops it.
set -euo pipefail

source "$(dirname "$0")/lib.sh"

MANJIKAZE="$TEST_TMP/manjikaze"
ORDER="$TEST_TMP/order"
unset XDG_CURRENT_DESKTOP

# Every stub below appends what it was asked to $ORDER, so the test can see what ran in which order.
# sudo runs nothing: it only records the command.
stub() {
    printf '#!/bin/bash\n%s\n' "$2" > "$TEST_TMP/bin/$1"
    chmod +x "$TEST_TMP/bin/$1"
}

stub gum 'case "$1" in
    log) echo "${*: -1}" >&2 ;;
    confirm) [[ -z ${GUM_DECLINE:-} || ! "$*" =~ $GUM_DECLINE ]] ;;
    choose) cat ;;
esac'
stub sudo 'echo "sudo $*" >> "$TEST_TMP/order"
[[ -z ${SUDO_FAIL:-} || ! "$*" =~ $SUDO_FAIL ]]'
stub checkupdates 'echo checkupdates >> "$TEST_TMP/order"
if [[ -n ${REPO_UPDATES:-} ]]; then echo "$REPO_UPDATES"; else exit 2; fi'
stub yay 'if [[ $1 == -Qua ]]; then echo "${AUR_UPDATES:-}"; exit 0; fi
echo "yay $*" >> "$TEST_TMP/order"
[[ $1 != -Si ]]'
stub pacman 'echo "pacman $*" >> "$TEST_TMP/order"
exit 1'
stub df 'printf "Avail\n%s\n" "${FREE_BYTES:-107374182400}"'
stub paccache ''
stub mise 'echo "mise $*" >> "$TEST_TMP/order"'
stub gsettings ''
stub clear ''

# A development checkout with one pending migration, and updates for one repository and one AUR package.
new_manjikaze() {
    rm -rf "$MANJIKAZE" "$HOME" "$ORDER"
    mkdir -p "$MANJIKAZE/bin" "$MANJIKAZE/migrations" "$HOME"
    cp "$ROOT/bin/manjikaze" "$MANJIKAZE/bin/"
    cp -r "$ROOT/lib" "$ROOT/app" "$MANJIKAZE/"
    echo '{"migrations": {}, "audits": {}, "updates": {}}' > "$MANJIKAZE/.manjikaze_state.json"
    printf '#!/bin/bash\nset -e\n\necho migration >> "$TEST_TMP/order"\n' > "$MANJIKAZE/migrations/1000000001_pending.sh"
    export REPO_UPDATES="htop 3.3.0-1 -> 3.4.0-1" AUR_UPDATES="yazi-bin 1.0-1 -> 1.1-1"
    export GUM_DECLINE="" SUDO_FAIL="" FREE_BYTES=107374182400
}

# Prints the number of the first line in $ORDER that matches, or nothing.
line_of() {
    grep -n -m 1 -E "$1" "$ORDER" | cut -d: -f1 || true
}

ran() {
    [[ -f $ORDER ]] && grep -q -E "$1" "$ORDER"
}

new_manjikaze
run "$MANJIKAZE/bin/manjikaze" update
[[ $exit_code -eq 0 ]] || fail "the update succeeds" "$(errors)"
upgrade=$(line_of "pacman -Su")
migration=$(line_of "^migration$")
aur=$(line_of "^yay -S --needed .*yazi-bin")
prune=$(line_of "paccache -rk2")
[[ -n $upgrade && -n $migration && -n $aur ]] || fail "the update upgrades, migrates and builds the AUR package" "$(cat "$ORDER")"
((upgrade < migration && migration < aur)) || fail "migrations run after the system packages and before the AUR packages" "$(cat "$ORDER")"
[[ -n $prune ]] && ((prune < upgrade)) || fail "the package cache is pruned before the upgrade" "$(cat "$ORDER")"
if [[ -d /run/systemd/system ]]; then
    ran "^sudo systemd-run --scope --quiet --collect pacman -Su" || fail "pacman upgrades in a scope of the system manager" "$(cat "$ORDER")"
fi
pass "system packages, then migrations, then AUR packages"

new_manjikaze
export GUM_DECLINE="system repository packages"
run "$MANJIKAZE/bin/manjikaze" update
[[ $exit_code -eq 0 ]] || fail "an update without the system packages succeeds" "$(errors)"
! ran "pacman -S" || fail "declining the system packages leaves the package databases alone" "$(cat "$ORDER")"
! ran "^yay -S" || fail "AUR packages aren't built while system packages wait for an update" "$(cat "$ORDER")"
ran "^migration$" || fail "the migrations still run" "$(cat "$ORDER")"
pass "AUR packages wait for the system packages"

new_manjikaze
export SUDO_FAIL="pacman -Su"
run "$MANJIKAZE/bin/manjikaze" update
[[ $exit_code -ne 0 ]] || fail "the update fails when the system upgrade fails"
! ran "^migration$" || fail "a failed upgrade stops before the migrations" "$(cat "$ORDER")"
! ran "^yay -S" || fail "a failed upgrade stops before the AUR packages" "$(cat "$ORDER")"
pass "a failed system upgrade stops the update"

new_manjikaze
export FREE_BYTES=$((2 * 1024 * 1024 * 1024)) GUM_DECLINE="Update anyway"
run "$MANJIKAZE/bin/manjikaze" update
grep -q "Only 2 GiB is free" "$TEST_TMP/err" || fail "the update says how much space is free" "$(errors)"
! ran "pacman -S|paccache" || fail "the update stops when too little space is free" "$(cat "$ORDER")"
export GUM_DECLINE=""
run "$MANJIKAZE/bin/manjikaze" update
ran "pacman -Su" || fail "the update goes ahead when told to" "$(cat "$ORDER")"
pass "too little free space stops the update unless confirmed"
