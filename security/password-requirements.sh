sudo pacman -S libpwquality --noconfirm

# Function to check password strength
check_password_strength() {
    local password="$1"
    local min_length=12
    local min_class=4  # Require lowercase, uppercase, digit, and special character

    # Check password strength using pwscore
    local score=$(echo "$password" | pwscore)
    
    if [ $? -ne 0 ] || [ "$score" -lt 50 ]; then
        echo "Password is too weak. It should have at least $min_length characters, including lowercase, uppercase, numbers, and special characters."
        return 1
    fi
    
    return 0
}

# Function to verify sudo password
verify_sudo_password() {
    local password="$1"
    echo "$password" | sudo -S echo "" >/dev/null 2>&1
    return $?
}

# Main script
echo "Please enter your current password to check its strength:"
read -s password

if check_password_strength "$password"; then
    if verify_sudo_password "$password"; then
        echo "Password is strong and valid for sudo."
    else
        echo "Password is strong but not valid for sudo."
    fi
else
    echo "Password does not meet the strength requirements."
fi
