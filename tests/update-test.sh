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

stub gum 'echo "$*" >> "$TEST_TMP/gum.calls"
case "$1" in
    log) echo "${*: -1}" >&2 ;;
    confirm) [[ -z ${GUM_DECLINE:-} || ! "$*" =~ $GUM_DECLINE ]] ;;
    choose) cat ;;
esac'
stub sudo 'echo "sudo $*" >> "$TEST_TMP/order"
if [[ "$*" == *"pacman -Su"* ]]; then printf "%s\n" "${PACMAN_OUTPUT:-}"; fi
[[ -z ${SUDO_FAIL:-} || ! "$*" =~ $SUDO_FAIL ]]'
stub checkupdates 'echo checkupdates >> "$TEST_TMP/order"
if [[ -n ${REPO_UPDATES:-} ]]; then echo "$REPO_UPDATES"; else exit 2; fi'
stub yay 'if [[ $1 == -Qua ]]; then echo "${AUR_UPDATES:-}"; exit 0; fi
echo "yay $*" >> "$TEST_TMP/order"
[[ $1 != -Si && -z ${YAY_FAIL:-} ]]'
stub pacman 'echo "pacman $*" >> "$TEST_TMP/order"
[[ $1 == -Qo && -z ${KERNEL_REPLACED:-} ]]'
stub modinfo '[[ -n ${NVIDIA_INSTALLED:-} ]] && echo "$NVIDIA_INSTALLED"'
stub fwupdmgr 'echo "fwupdmgr $*" >> "$TEST_TMP/order"
case "$1" in
    get-updates) echo "$FIRMWARE_JSON" ;;
    security)
        if [[ " $* " == *" --json "* ]]; then
            echo "{\"SecurityAttributes\": []}"
        else
            printf "Host Security ID: \e[1mHSI:2! (v2.1.8)\e[0m\n\nHSI-1\n"
        fi
        ;;
esac'
stub df 'printf "Avail\n%s\n" "${FREE_BYTES:-107374182400}"'
stub paccache ''
stub mise 'echo "mise $*${MISE_MINIMUM_RELEASE_AGE:+ (age $MISE_MINIMUM_RELEASE_AGE)}" >> "$TEST_TMP/order"
if [[ $1 == outdated ]]; then echo "${MISE_OUTDATED:-}"; fi'
stub gsettings ''
stub clear ''

# A development checkout with one pending migration, and updates for one repository and one AUR package.
new_manjikaze() {
    rm -rf "$MANJIKAZE" "$HOME" "$ORDER" "$TEST_TMP"/*.calls
    mkdir -p "$MANJIKAZE/bin" "$MANJIKAZE/migrations" "$HOME"
    cp "$ROOT/bin/manjikaze" "$MANJIKAZE/bin/"
    cp -r "$ROOT/lib" "$ROOT/app" "$MANJIKAZE/"
    echo '{"migrations": {}, "audits": {}, "updates": {}}' > "$MANJIKAZE/.manjikaze_state.json"
    printf '#!/bin/bash\nset -e\n\necho migration >> "$TEST_TMP/order"\n' > "$MANJIKAZE/migrations/1000000001_pending.sh"
    export REPO_UPDATES="htop 3.3.0-1 -> 3.4.0-1" AUR_UPDATES="yazi-bin 1.0-1 -> 1.1-1"
    export GUM_DECLINE="" SUDO_FAIL="" YAY_FAIL="" PACMAN_OUTPUT="" FREE_BYTES=107374182400
    # The running kernel is installed, and there is no microcode or NVIDIA driver.
    export UPDATE_KERNEL_MODULES_DIR="$TEST_TMP/modules" UPDATE_BOOT_DIR="$TEST_TMP/boot" UPDATE_SYS_MODULE_DIR="$TEST_TMP/sys"
    export KERNEL_REPLACED="" NVIDIA_INSTALLED="" FIRMWARE_JSON='{"Devices": []}' MISE_OUTDATED=""
    rm -rf "$UPDATE_KERNEL_MODULES_DIR" "$UPDATE_BOOT_DIR" "$UPDATE_SYS_MODULE_DIR"
    mkdir -p "$UPDATE_KERNEL_MODULES_DIR/$(uname -r)" "$UPDATE_BOOT_DIR" "$UPDATE_SYS_MODULE_DIR"
    touch "$UPDATE_KERNEL_MODULES_DIR/$(uname -r)/modules.builtin"
}

# The update runs in script, which passes what it shows through its terminal to stdout.
said() {
    cat "$TEST_TMP/out" "$TEST_TMP/err" | grep -q -- "$1"
}

# A git install in ~/.manjikaze whose remote has one commit more.
new_git_install() {
    new_manjikaze
    local git=(git -c user.name=Test -c user.email=test@example.com)
    rm -rf "$TEST_TMP/remote.git" "$TEST_TMP/other"
    git init -q --bare "$TEST_TMP/remote.git"
    git clone -q "$TEST_TMP/remote.git" "$HOME/.manjikaze" 2> /dev/null
    cp -r "$MANJIKAZE"/. "$HOME/.manjikaze/"
    "${git[@]}" -C "$HOME/.manjikaze" add -A
    "${git[@]}" -C "$HOME/.manjikaze" commit -q -m first
    "${git[@]}" -C "$HOME/.manjikaze" push -q -u origin HEAD 2> /dev/null
    git clone -q "$TEST_TMP/remote.git" "$TEST_TMP/other"
    touch "$TEST_TMP/other/pulled"
    "${git[@]}" -C "$TEST_TMP/other" add pulled
    "${git[@]}" -C "$TEST_TMP/other" commit -q -m second
    "${git[@]}" -C "$TEST_TMP/other" push -q 2> /dev/null
}

asked() {
    [[ -f $TEST_TMP/gum.calls ]] && grep -q -E "^(confirm|choose)" "$TEST_TMP/gum.calls"
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
said "Only 2 GiB is free" || fail "the update says how much space is free" "$(output)"
! ran "pacman -S|paccache" || fail "the update stops when too little space is free" "$(cat "$ORDER")"
export GUM_DECLINE=""
run "$MANJIKAZE/bin/manjikaze" update
ran "pacman -Su" || fail "the update goes ahead when told to" "$(cat "$ORDER")"
pass "too little free space stops the update unless confirmed"

new_manjikaze
export GUM_DECLINE=".*"
run "$MANJIKAZE/bin/manjikaze" update -y
[[ $exit_code -eq 0 ]] || fail "an unattended update succeeds" "$(errors)"
! asked || fail "an unattended update asks nothing" "$(cat "$TEST_TMP/gum.calls")"
ran "pacman -Su" && ran "^migration$" && ran "^yay -S --needed .*yazi-bin" ||
    fail "an unattended update updates the system and AUR packages and runs the migrations" "$(cat "$ORDER")"
pass "an unattended update asks nothing and updates everything"

new_manjikaze
export REPO_UPDATES="linux612 6.12.1-1 -> 6.12.2-1" KERNEL_REPLACED=1
run "$MANJIKAZE/bin/manjikaze" update -y
! ran "^sudo reboot" || fail "an unattended update doesn't reboot" "$(cat "$ORDER")"
said "doesn't reboot" || fail "an unattended update says a reboot is needed" "$(output)"
pass "an unattended update leaves the reboot to the user"

new_manjikaze
export FREE_BYTES=$((2 * 1024 * 1024 * 1024))
run "$MANJIKAZE/bin/manjikaze" update -y
[[ $exit_code -ne 0 ]] || fail "an unattended update fails when too little space is free"
! ran "pacman -S" || fail "an unattended update doesn't start without the space" "$(cat "$ORDER")"
pass "an unattended update stops when too little space is free"

new_manjikaze
export YAY_FAIL=1
run "$MANJIKAZE/bin/manjikaze" update -y
[[ $exit_code -ne 0 ]] || fail "an unattended update fails when an AUR package fails"
ran "^mise install" || fail "the steps after a failed AUR package still run" "$(cat "$ORDER")"
run "$MANJIKAZE/bin/manjikaze" update
[[ $exit_code -eq 0 ]] || fail "an interactive update reports a failed AUR package without failing" "$(errors)"
pass "an unattended update finishes and then fails when an AUR package failed"

new_manjikaze
export REPO_UPDATES="" AUR_UPDATES=""
mkdir -p "$MANJIKAZE/configs/mise" "$HOME/.config/mise/conf.d"
printf '[tools]\nclaude = "latest"\n' > "$MANJIKAZE/configs/mise/claude.toml"
cp "$MANJIKAZE/configs/mise/claude.toml" "$HOME/.config/mise/conf.d/manjikaze-claude.toml"
export MISE_OUTDATED='{"claude": {"name": "claude", "requested": "latest", "current": "2.1.320", "latest": "2.1.323"}}'
run "$MANJIKAZE/bin/manjikaze" update -y
[[ $exit_code -eq 0 ]] || fail "an update with only a newer mise tool succeeds" "$(errors)"
said "claude (2.1.320 → 2.1.323)" || fail "the update lists the newer release of a tool on latest" "$(output)"
ran "^mise outdated --json claude \(age 24h\)$" || fail "only releases that are a day old count" "$(cat "$ORDER")"
ran "^mise upgrade claude \(age 24h\)$" || fail "the update upgrades the tools on latest" "$(cat "$ORDER")"
pass "tools on latest get the newest release that is a day old"

new_git_install
export GUM_DECLINE=".*"
run "$HOME/.manjikaze/bin/manjikaze" update -y
[[ -f $HOME/.manjikaze/pulled ]] || fail "an unattended update updates the git install" "$(errors)"
! asked || fail "updating the git install asks nothing" "$(cat "$TEST_TMP/gum.calls")"
ran "pacman -Su" || fail "the update goes on after updating the git install" "$(cat "$ORDER")"
pass "an unattended update updates a git install of Manjikaze first"

new_manjikaze
run "$MANJIKAZE/bin/manjikaze" update
logs=("$HOME"/.local/state/manjikaze/updates/update-*.log)
[[ ${#logs[@]} -eq 1 && -f ${logs[0]} ]] || fail "an update writes one log" "$(ls -la "$HOME/.local/state/manjikaze/updates" 2>&1)"
grep -q "Updating system packages" "${logs[0]}" || fail "the log records what the update showed" "$(cat "${logs[0]}")"
grep -q 'COMMAND_EXIT_CODE="0"' "${logs[0]}" || fail "the log records the exit code" "$(cat "${logs[0]}")"
said "The log of this update is in ${logs[0]}" || fail "the update says where its log is" "$(output)"
pass "every update leaves a log of its terminal"

new_manjikaze
export REPO_UPDATES="linux612 6.12.1-1 -> 6.12.2-1" KERNEL_REPLACED=1
export PACMAN_OUTPUT=$'==> Building image from preset: /etc/mkinitcpio.d/linux612.preset: \'default\'\n==> ERROR: specified kernel image does not exist'
run "$MANJIKAZE/bin/manjikaze" update
[[ $exit_code -ne 0 ]] || fail "the update fails when an initramfs image wasn't built"
! ran "^sudo reboot" || fail "the update doesn't reboot when an initramfs image wasn't built" "$(cat "$ORDER")"
said "may not boot" || fail "the update says the system may not boot" "$(output)"
pass "an initramfs image that wasn't built stops the reboot"

new_manjikaze
export REPO_UPDATES="linux612 6.12.1-1 -> 6.12.2-1"
run "$MANJIKAZE/bin/manjikaze" update
! ran "^sudo reboot" || fail "a kernel package update that leaves the running kernel installed needs no reboot" "$(cat "$ORDER")"
new_manjikaze
export KERNEL_REPLACED=1
run "$MANJIKAZE/bin/manjikaze" update
ran "^sudo reboot" || fail "a replaced running kernel needs a reboot" "$(cat "$ORDER")"
said "The running kernel $(uname -r) was replaced" || fail "the update says why it reboots" "$(output)"
new_manjikaze
export KERNEL_REPLACED=1 REPO_UPDATES="" AUR_UPDATES=""
run "$MANJIKAZE/bin/manjikaze" update
ran "^sudo reboot" || fail "an update without updates offers the reboot an earlier update needs" "$(cat "$ORDER")"
pass "the running kernel decides whether a kernel update needs a reboot"

new_manjikaze
touch -d "2000-01-01" "$UPDATE_BOOT_DIR/intel-ucode.img"
run "$MANJIKAZE/bin/manjikaze" update
! ran "^sudo reboot" || fail "microcode from before the boot needs no reboot" "$(cat "$ORDER")"
new_manjikaze
touch -d "+1 hour" "$UPDATE_BOOT_DIR/intel-ucode.img"
run "$MANJIKAZE/bin/manjikaze" update
ran "^sudo reboot" || fail "microcode updated since the boot needs a reboot" "$(cat "$ORDER")"
pass "microcode updated since the boot needs a reboot"

new_manjikaze
mkdir -p "$UPDATE_SYS_MODULE_DIR/nvidia"
echo "580.95.05" > "$UPDATE_SYS_MODULE_DIR/nvidia/version"
export NVIDIA_INSTALLED="580.95.05"
run "$MANJIKAZE/bin/manjikaze" update
! ran "^sudo reboot" || fail "a loaded NVIDIA driver of the installed version needs no reboot" "$(cat "$ORDER")"
export NVIDIA_INSTALLED="580.105.08"
run "$MANJIKAZE/bin/manjikaze" update
ran "^sudo reboot" || fail "a loaded NVIDIA driver older than the installed one needs a reboot" "$(cat "$ORDER")"
pass "an NVIDIA driver update needs a reboot"

new_manjikaze
printf '#!/bin/bash\nset -e\n\nrequire_reboot "The test changed something only a reboot applies."\n' > "$MANJIKAZE/migrations/1000000002_needs_reboot.sh"
run "$MANJIKAZE/bin/manjikaze" update
ran "^sudo reboot" || fail "a migration that requires a reboot gets one" "$(cat "$ORDER")"
said "The test changed something only a reboot applies." || fail "the update gives the migration's reason" "$(output)"
new_manjikaze
mkdir -p "$HOME/.local/state/manjikaze"
printf '%s\n%s\n' "00000000-0000-0000-0000-000000000000" "From an earlier boot." > "$HOME/.local/state/manjikaze/reboot-required"
run "$MANJIKAZE/bin/manjikaze" update
! ran "^sudo reboot" || fail "a reboot request from an earlier boot is done" "$(cat "$ORDER")"
pass "a migration can require a reboot until the next boot"

firmware_update='{"Devices": [{"Name": "System Firmware", "Version": "1.2.3", "Releases": [{"Version": "1.3.0"}]}]}'
security_file="$HOME/.local/state/manjikaze/host-security.json"

new_manjikaze
run "$MANJIKAZE/bin/manjikaze" update
said "Firmware is up to date." && said "Host Security ID: HSI:2! (v2.1.8)." ||
    fail "without firmware updates, the update says so and shows the Host Security ID" "$(output)"
new_manjikaze
export FIRMWARE_JSON=$firmware_update
run "$MANJIKAZE/bin/manjikaze" update
said "System Firmware: 1.2.3 → 1.3.0" && said "manjikaze firmware" || fail "the update reports firmware updates" "$(output)"
! ran "fwupdmgr update" || fail "the update doesn't install firmware" "$(cat "$ORDER")"
[[ $(jq -r .HostSecurityId "$security_file") == "HSI:2! (v2.1.8)" ]] || fail "the update records the Host Security ID" "$(cat "$security_file" 2>&1)"
jq -e '.Checked and .SecurityAttributes' "$security_file" > /dev/null || fail "the record keeps fwupd's report and the time of the check" "$(cat "$security_file")"
new_manjikaze
export FIRMWARE_JSON=$firmware_update REPO_UPDATES="" AUR_UPDATES=""
run "$MANJIKAZE/bin/manjikaze" update
said "System Firmware: 1.2.3 → 1.3.0" || fail "an update without package updates reports firmware updates too" "$(output)"
pass "the update reports firmware updates and records the host security, without installing firmware"

new_manjikaze
export FIRMWARE_JSON=$firmware_update GUM_DECLINE="Install the firmware"
run "$MANJIKAZE/bin/manjikaze" firmware
said "HSI:2! (v2.1.8)" || fail "manjikaze firmware shows the Host Security ID" "$(output)"
! ran "fwupdmgr update" || fail "manjikaze firmware asks before it installs" "$(cat "$ORDER")"
export GUM_DECLINE=""
run "$MANJIKAZE/bin/manjikaze" firmware
ran "^sudo fwupdmgr update" || fail "manjikaze firmware installs the updates when told to" "$(cat "$ORDER")"
new_manjikaze
run "$MANJIKAZE/bin/manjikaze" firmware
said "All firmware is up to date" && ! ran "fwupdmgr update" || fail "manjikaze firmware without updates installs nothing" "$(output)"
pass "manjikaze firmware installs firmware updates after asking"

# check_update_log and new_update_log on their own.
status() { echo "$1"; }
source "$ROOT/lib/update.sh"
sample="$TEST_TMP/sample.log"

printf '%s\r\n' "==> Building image from preset: 'default'" $'\e[1m\e[32m==> Initcpio image generation successful\e[0m' > "$sample"
run check_update_log "$sample"
[[ $exit_code -eq 0 && -z $(output) ]] || fail "a log with a successful build reports nothing" "code $exit_code: $(output)"

printf '%s\r\n' "==> Building image from preset: 'default'" $'\e[1m\e[31m==> ERROR:\e[0m file not found: x.rules' \
    "==> WARNING: errors were encountered during the build. The image may not be complete." > "$sample"
run check_update_log "$sample"
[[ $exit_code -eq 0 ]] || fail "an image built with errors doesn't stop the update" "$(output)"
grep -q "may not be complete" "$TEST_TMP/out" && grep -q "  ==> ERROR: file not found: x.rules$" "$TEST_TMP/out" ||
    fail "an image built with errors is reported with its errors" "$(output)"

printf '%s\r\n' "==> Building image from preset: 'default'" "==> ERROR: Initcpio image generation FAILED: 'zstd' reported an error" > "$sample"
run check_update_log "$sample"
[[ $exit_code -ne 0 ]] || fail "a failed image stops the update" "$(output)"

printf '%s\r\n' "warning: /etc/pacman.conf installed as /etc/pacman.conf.pacnew" "Error! Bad return status for module build on kernel: 6.12" > "$sample"
run check_update_log "$sample"
grep -q "^  /etc/pacman.conf.pacnew$" "$TEST_TMP/out" || fail "new .pacnew files are listed" "$(output)"
grep -q "Bad return status for module build" "$TEST_TMP/out" || fail "a DKMS build that failed is reported" "$(output)"
pass "the log check stops on missing images and reports incomplete ones, DKMS errors and .pacnew files"

mkdir -p "$UPDATE_LOG_DIR"
for day in $(seq -w 1 65); do
    touch "$UPDATE_LOG_DIR/update-2026-01-${day}T000000.log"
done
new_log=$(new_update_log)
remaining=("$UPDATE_LOG_DIR"/update-*.log)
[[ ${#remaining[@]} -eq $((UPDATE_LOGS_KEPT - 1)) ]] || fail "old logs are removed down to UPDATE_LOGS_KEPT with the new one" "${#remaining[@]} left"
[[ ! -e $UPDATE_LOG_DIR/update-2026-01-01T000000.log && -e $UPDATE_LOG_DIR/update-2026-01-65T000000.log ]] ||
    fail "the oldest logs are the ones removed"
[[ $new_log == "$UPDATE_LOG_DIR"/update-*.log ]] || fail "new_update_log prints a path in the log directory" "$new_log"
pass "the newest logs are kept"
