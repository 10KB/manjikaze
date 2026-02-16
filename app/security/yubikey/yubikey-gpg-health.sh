# YubiKey GPG Health Check
# Read-only diagnostic — safe to run at any time.

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

check_pass() { echo -e "  ${GREEN}✅${NC} $1"; }
check_warn() { echo -e "  ${YELLOW}⚠️${NC}  $1"; }
check_fail() { echo -e "  ${RED}❌${NC} $1"; }
check_info() { echo -e "  ${DIM}ℹ️${NC}  $1"; }

format_expiry() {
    local days=$1
    if [[ $days -lt 0 ]]; then echo -e "${RED}EXPIRED ${days#-} days ago${NC}"
    elif [[ $days -lt 30 ]]; then echo -e "${RED}${days} days${NC}"
    elif [[ $days -lt 180 ]]; then echo -e "${YELLOW}${days} days${NC}"
    else echo -e "${GREEN}${days} days${NC}"
    fi
}

yubikey_gpg_health() {
    echo ""
    gum style \
        --border double --border-foreground 39 \
        --padding "1 2" --margin "0 1" \
        "🔍 YubiKey GPG/SSH Health Check"
    echo ""
    local issues=0 warnings=0

    # ── YubiKey presence ───────────────────────────────────────────────
    echo -e "${BOLD}YubiKey Hardware${NC}"
    if ! command -v ykman &>/dev/null; then check_fail "ykman not installed"; return 1; fi

    local ykman_info
    ykman_info=$(ykman info 2>/dev/null)
    if [[ $? -ne 0 ]]; then check_fail "No YubiKey detected"; return 1; fi

    local yk_serial yk_firmware
    yk_serial=$(echo "$ykman_info" | grep "Serial number:" | awk '{print $3}')
    yk_firmware=$(echo "$ykman_info" | grep "Firmware version:" | awk '{print $3}')
    check_pass "$(echo "$ykman_info" | head -1) (Serial: ${yk_serial:-?}, FW: ${yk_firmware:-?})"

    # ── OpenPGP card ───────────────────────────────────────────────────
    echo "" && echo -e "${BOLD}OpenPGP Card${NC}"
    local card_status
    card_status=$(gpg --card-status 2>&1)
    if [[ $? -ne 0 ]]; then
        check_fail "Cannot read card"; ((issues++))
    else
        if echo "$card_status" | grep -q "General key info" && \
           ! echo "$card_status" | grep "Signature key" | grep -q "\[none\]"; then
            check_pass "Keys present on card"
            local key_fp
            key_fp=$(echo "$card_status" | grep "key fingerprint" | head -1 | sed 's/.*= //')
            [[ -n "$key_fp" ]] && check_info "Fingerprint: $key_fp"
        else
            check_fail "No keys on card"; ((issues++))
        fi

        if echo "$card_status" | grep -q "KDF setting.*on"; then
            check_pass "KDF enabled"
        else check_warn "KDF not enabled"; ((warnings++)); fi

        local login_data
        login_data=$(echo "$card_status" | grep "^Login data" | sed 's/Login data[^:]*: *//')
        if [[ -n "$login_data" && "$login_data" != "(null)" ]]; then
            check_pass "Login: $login_data"
        else check_warn "Login attribute not set"; ((warnings++)); fi

        local pin_retries
        pin_retries=$(echo "$card_status" | grep "PIN retry counter" | sed 's/PIN retry counter[^:]*: *//')
        [[ -n "$pin_retries" ]] && check_info "PIN retries: $pin_retries"
    fi

    # ── Key expiry ─────────────────────────────────────────────────────
    echo "" && echo -e "${BOLD}Key Expiry${NC}"
    local now has_keys=false
    now=$(date +%s)
    while IFS=: read -r type validity length algo keyid created expires _ _ _ _ usage _; do
        if [[ "$type" == "sub" ]]; then
            has_keys=true
            local name="Unknown"
            [[ "$usage" == *s* ]] && name="Sign"
            [[ "$usage" == *e* ]] && name="Encrypt"
            [[ "$usage" == *a* ]] && name="Auth"
            if [[ -z "$expires" || "$expires" == "0" ]]; then
                check_pass "$name: never expires"
            else
                local days=$(( (expires - now) / 86400 ))
                local date_str
                date_str=$(date -d "@$expires" +%F 2>/dev/null)
                local fmt
                fmt=$(format_expiry "$days")
                if [[ $days -lt 30 ]]; then check_fail "$name: $date_str ($fmt)"; ((issues++))
                elif [[ $days -lt 180 ]]; then check_warn "$name: $date_str ($fmt)"; ((warnings++))
                else check_pass "$name: $date_str ($fmt)"; fi
            fi
        fi
    done < <(gpg -k --with-colons 2>/dev/null)
    $has_keys || { check_fail "No GPG keys in keyring"; ((issues++)); }

    # ── Trust ──────────────────────────────────────────────────────────
    echo "" && echo -e "${BOLD}Trust & Policies${NC}"
    local trust
    trust=$(gpg -k --with-colons 2>/dev/null | awk -F: '/^pub:/ { print $2; exit }')
    case "$trust" in
        u) check_pass "Trust: Ultimate" ;;
        f) check_pass "Trust: Full" ;;
        m) check_warn "Trust: Marginal"; ((warnings++)) ;;
        *) check_warn "Trust: $trust"; ((warnings++)) ;;
    esac

    # Touch policies
    local openpgp_info
    openpgp_info=$(ykman openpgp info 2>/dev/null)
    if [[ -n "$openpgp_info" ]]; then
        local t_sig t_aut t_dec
        t_sig=$(echo "$openpgp_info" | grep -A2 "^Signature key:" | grep "Touch policy:" | awk '{print $NF}')
        t_dec=$(echo "$openpgp_info" | grep -A2 "^Decryption key:" | grep "Touch policy:" | awk '{print $NF}')
        t_aut=$(echo "$openpgp_info" | grep -A2 "^Authentication key:" | grep "Touch policy:" | awk '{print $NF}')
        if [[ "$t_sig" == "On" && "$t_aut" == "On" && "$t_dec" == "On" ]]; then
            check_pass "Touch: sig=on aut=on dec=on"
        else check_warn "Touch: sig=${t_sig:-?} aut=${t_aut:-?} dec=${t_dec:-?}"; ((warnings++)); fi
    fi

    # ── SSH ────────────────────────────────────────────────────────────
    echo "" && echo -e "${BOLD}SSH${NC}"
    local expected_sock
    expected_sock=$(gpgconf --list-dirs agent-ssh-socket 2>/dev/null)
    if [[ "$SSH_AUTH_SOCK" == "$expected_sock" ]]; then check_pass "SSH_AUTH_SOCK → gpg-agent"
    else check_fail "SSH_AUTH_SOCK: ${SSH_AUTH_SOCK:-unset} (expected: $expected_sock)"; ((issues++)); fi

    [[ -f ~/.ssh/id_rsa_yubikey.pub ]] && check_pass "Key file: ~/.ssh/id_rsa_yubikey.pub" || { check_fail "Key file missing"; ((issues++)); }

    local ssh_keys
    ssh_keys=$(ssh-add -L 2>/dev/null)
    if [[ $? -eq 0 && -n "$ssh_keys" ]] && ! echo "$ssh_keys" | grep -q "no identities"; then
        check_pass "SSH agent: $(echo "$ssh_keys" | wc -l) key(s)"
    else check_warn "SSH agent: no keys loaded"; ((warnings++)); fi

    local gk="$HOME/.config/autostart/gnome-keyring-ssh.desktop"
    if [[ -f "$gk" ]] && grep -q "Hidden=true" "$gk"; then check_pass "gnome-keyring SSH: disabled"
    elif [[ -f /etc/xdg/autostart/gnome-keyring-ssh.desktop ]]; then check_warn "gnome-keyring SSH: may conflict"; ((warnings++))
    else check_pass "gnome-keyring SSH: not present"; fi

    # ── Git ────────────────────────────────────────────────────────────
    echo "" && echo -e "${BOLD}Git${NC}"
    local gsk
    gsk=$(git config --global --get user.signingkey 2>/dev/null)
    [[ -n "$gsk" ]] && check_pass "Signing key: $gsk" || { check_fail "No signing key"; ((issues++)); }
    [[ "$(git config --global --get commit.gpgsign)" == "true" ]] && check_pass "Commit signing: on" || { check_warn "Commit signing: off"; ((warnings++)); }
    [[ "$(git config --global --get tag.gpgSign)" == "true" ]] && check_pass "Tag signing: on" || { check_warn "Tag signing: off"; ((warnings++)); }

    # ── Systemd & Shell ────────────────────────────────────────────────
    echo "" && echo -e "${BOLD}Services & Shell${NC}"
    systemctl --user is-enabled gpg-agent.socket &>/dev/null && check_pass "gpg-agent.socket: enabled" || { check_warn "gpg-agent.socket: not enabled"; ((warnings++)); }
    systemctl --user is-enabled gpg-agent-ssh.socket &>/dev/null && check_pass "gpg-agent-ssh.socket: enabled" || { check_warn "gpg-agent-ssh.socket: not enabled"; ((warnings++)); }
    [[ -f "$HOME/.oh-my-zsh/custom/plugins/yubikey-gpg/yubikey-gpg.plugin.zsh" ]] && check_pass "Zsh plugin: installed" || { check_fail "Zsh plugin: missing"; ((issues++)); }

    # ── Summary ────────────────────────────────────────────────────────
    echo ""
    echo "──────────────────────────────────────────────────────────────────"
    if [[ $issues -eq 0 && $warnings -eq 0 ]]; then
        echo -e "  ${GREEN}${BOLD}All checks passed!${NC}"
    elif [[ $issues -eq 0 ]]; then
        echo -e "  ${YELLOW}${BOLD}$warnings warning(s)${NC} — functional but could be improved."
    else
        echo -e "  ${RED}${BOLD}$issues issue(s)${NC}, ${YELLOW}$warnings warning(s)${NC}"
    fi
    echo ""
}

yubikey_gpg_health
