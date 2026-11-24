#!/bin/bash
# Installing Tailscale from Tailscale's own binaries, and moving to them from the tailscale package.
set -euo pipefail

source "$(dirname "$0")/lib.sh"

export MANJIKAZE_DIR="$ROOT" TAILSCALE_ROOT="$TEST_TMP/root"
ORDER="$TEST_TMP/order"
PACKAGE="$TEST_TMP/package"

stub() {
    printf '#!/bin/bash\n%s\n' "$2" > "$TEST_TMP/bin/$1"
    chmod +x "$TEST_TMP/bin/$1"
}

# sudo runs the command, so the files land in $TAILSCALE_ROOT. The other stubs append what they
# were asked to $ORDER.
stub sudo '"$@"'
stub pacman 'case "$1" in
    -Qi) [[ -e "$TEST_TMP/package" ]] ;;
    -R)
        echo "pacman $*" >> "$TEST_TMP/order"
        [[ -z ${PACMAN_FAIL:-} ]] || exit 1
        rm "$TEST_TMP/package"
        # pacman keeps a changed configuration file as .pacsave.
        if [[ -n ${CHANGED_PORT:-} ]]; then
            mkdir -p "$TAILSCALE_ROOT/etc/default"
            echo "PORT=\"$CHANGED_PORT\"" > "$TAILSCALE_ROOT/etc/default/tailscaled.pacsave"
        fi
        ;;
esac'
stub systemctl 'echo "systemctl $*" >> "$TEST_TMP/order"
[[ $1 != is-enabled || -n ${ENABLED:-} ]]'
stub tailscale 'echo "tailscale $*" >> "$TEST_TMP/order"'
stub curl 'url=${*: -1}
echo "curl ${url##*/}" >> "$TEST_TMP/order"
while [[ $# -gt 1 ]]; do
    if [[ $1 == -o ]]; then out=$2; fi
    shift
done
case "$url" in
    *mode=json) echo "{\"Tarballs\": {\"amd64\": \"tailscale_9.9.9_amd64.tgz\"}}" ;;
    *.tgz) cp "$TEST_TMP/release.tgz" "$out" ;;
    *.sha256) echo "${CHECKSUM:-$(sha256sum < "$TEST_TMP/release.tgz" | cut -d" " -f1)}" ;;
esac'

# A release as Tailscale publishes it: its units start Tailscale from /usr/bin and /usr/sbin.
release="$TEST_TMP/tailscale_9.9.9_amd64"
mkdir -p "$release/systemd"
printf '#!/bin/bash\necho "#compdef tailscale"\n' > "$release/tailscale"
printf '#!/bin/bash\n' > "$release/tailscaled"
chmod +x "$release/tailscale" "$release/tailscaled"
cat > "$release/systemd/tailscaled.service" << 'EOF'
[Service]
EnvironmentFile=/etc/default/tailscaled
ExecStart=/usr/sbin/tailscaled --port=${PORT} $FLAGS
ExecStopPost=/usr/sbin/tailscaled --cleanup
EOF
printf '[Service]\nExecStart=/usr/bin/tailscale wait\n' > "$release/systemd/tailscale-wait-online.service"
echo 'PORT="41641"' > "$release/systemd/tailscaled.defaults"
tar -czf "$TEST_TMP/release.tgz" -C "$TEST_TMP" tailscale_9.9.9_amd64

source "$ROOT/lib/common.sh"
source "$ROOT/lib/tailscale.sh"

BIN="$TAILSCALE_ROOT/usr/local/bin"
UNITS="$TAILSCALE_ROOT/etc/systemd/system"

# A workstation with the tailscale package, and tailscaled enabled.
new_workstation() {
    rm -rf "$TAILSCALE_ROOT"
    : > "$ORDER"
    touch "$PACKAGE"
    export ENABLED=yes PACMAN_FAIL="" CHANGED_PORT="" CHECKSUM=""
}

new_workstation
export CHANGED_PORT=12345
run install_tailscale_binaries
[[ $exit_code -eq 0 ]] || fail "the move from the tailscale package succeeds" "$(errors)"
[[ ! -e $PACKAGE ]] || fail "the tailscale package is removed" "$(cat "$ORDER")"
[[ -x $BIN/tailscale && -x $BIN/tailscaled ]] || fail "tailscale and tailscaled are in /usr/local/bin" "$(errors)"
grep -q '^ExecStart=/usr/local/bin/tailscaled ' "$UNITS/tailscaled.service" || fail "the unit starts tailscaled from /usr/local/bin" "$(cat "$UNITS/tailscaled.service")"
! grep -q '/usr/sbin' "$UNITS/tailscaled.service" || fail "the unit no longer names /usr/sbin" "$(cat "$UNITS/tailscaled.service")"
grep -q '^ExecStart=/usr/local/bin/tailscale wait' "$UNITS/tailscale-wait-online.service" || fail "the other units run tailscale from /usr/local/bin" "$(cat "$UNITS/tailscale-wait-online.service")"
grep -q 'PORT="12345"' "$TAILSCALE_ROOT/etc/default/tailscaled" || fail "a changed /etc/default/tailscaled is kept" "$(cat "$TAILSCALE_ROOT/etc/default/tailscaled")"
grep -q '^systemctl reenable tailscaled.service$' "$ORDER" || fail "tailscaled stays enabled" "$(cat "$ORDER")"
[[ $(tail -n 1 "$ORDER") == "systemctl try-restart tailscaled.service" ]] || fail "restarting tailscaled comes last" "$(cat "$ORDER")"
pass "the tailscale package makes way for Tailscale's binaries, with tailscaled enabled and its settings kept"

: > "$ORDER"
run install_tailscale_binaries
[[ $exit_code -eq 0 ]] || fail "a second run succeeds" "$(errors)"
[[ ! -s $ORDER ]] || fail "a second run downloads and restarts nothing" "$(cat "$ORDER")"
pass "Tailscale that is already in /usr/local/bin is left alone"

new_workstation
export CHECKSUM=0000000000000000000000000000000000000000000000000000000000000000
run install_tailscale_binaries
[[ $exit_code -ne 0 ]] || fail "a download that doesn't match its checksum fails the install"
[[ -e $PACKAGE ]] || fail "the tailscale package stays after a bad download" "$(cat "$ORDER")"
[[ ! -e $BIN/tailscaled ]] || fail "a bad download is not installed"
pass "a download that doesn't match its checksum changes nothing"

new_workstation
export PACMAN_FAIL=yes
run install_tailscale_binaries
[[ $exit_code -ne 0 ]] || fail "the install fails when pacman keeps the tailscale package"
[[ ! -e $BIN/tailscaled ]] || fail "nothing is installed next to a package that pacman keeps"
! grep -q 'restart' "$ORDER" || fail "tailscaled isn't restarted when the package stays" "$(cat "$ORDER")"
pass "a tailscale package that pacman won't remove stays in use"

new_workstation
export ENABLED=""
run install_tailscale_binaries
[[ $exit_code -eq 0 ]] || fail "the move succeeds when tailscaled isn't enabled" "$(errors)"
! grep -q -E '^systemctl (re)?enable' "$ORDER" || fail "tailscaled stays disabled" "$(cat "$ORDER")"
pass "the move doesn't enable a tailscaled that wasn't enabled"

new_workstation
rm "$PACKAGE"
export ENABLED=""
run install_tailscale
[[ $exit_code -eq 0 ]] || fail "installing on a workstation without Tailscale succeeds" "$(errors)"
grep -q 'PORT="41641"' "$TAILSCALE_ROOT/etc/default/tailscaled" || fail "the unit gets the /etc/default/tailscaled it reads" "$(errors)"
started=$(grep -n '^systemctl enable --now tailscaled.service$' "$ORDER" | cut -d: -f1)
updates=$(grep -n '^tailscale set --auto-update$' "$ORDER" | cut -d: -f1)
[[ -n $started && -n $updates && $started -lt $updates ]] || fail "the updates are switched on once tailscaled runs" "$(cat "$ORDER")"
pass "a new install starts tailscaled and switches on Tailscale's own updates"
