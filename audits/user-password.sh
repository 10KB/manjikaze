#!/bin/bash
# User Password Strength Audit
set -e

# Handle interrupt signal
trap 'echo -e "\nAudit interrupted by user"; exit 1' INT

check_password_strength() {
    local password="$1"

    # Check for empty password
    if [[ -z "$password" ]]; then
        echo "No password supplied"
        return 1
    fi

    # Run pwscore and capture output and result
    local output
    output=$(echo "$password" | pwscore 2>&1)
    local result=$?

    # If pwscore failed or score is too low
    if [[ $result -ne 0 || -n "$output" && "$output" -lt 50 ]]; then
        echo "Password is too weak. It should have at least 12 characters, including lowercase, uppercase, numbers, and special characters."
        echo "pwscore output: $output"
        return 1
    fi

    return 0
}

verify_sudo_password() {
    local password="$1"

    if [[ -z "$password" ]]; then
        return 1
    fi

    echo "$password" | sudo -S echo "" >/dev/null 2>&1
    return $?
}

install_package "libpwquality" "repo"

echo "This audit will check your password strength and validity."
echo "Press Ctrl+C at any time to cancel this audit."
password=$(gum input --password --prompt "Please enter your current password to check its strength: ")

# Validate password
if check_password_strength "$password"; then
    if verify_sudo_password "$password"; then
        echo "Password is strong and valid for sudo."
        exit 0
    else
        echo "Password is strong but not valid for sudo."
        exit 1
    fi
else
    echo "Password does not meet the strength requirements."
    exit 1
fi
