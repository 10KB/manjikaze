#!/bin/bash

# YubiKey OATH-TOTP setup for AWS Vault
#
# This script helps configure a YubiKey to generate TOTP codes for AWS MFA,
# enabling touch-based authentication with aws-vault instead of manual code entry.
#
# Note: AWS CLI/SDK does not support FIDO-U2F — only TOTP works for CLI-based MFA.
# This script uses the YubiKey's OATH-TOTP capability (via ykman) as the bridge.

setup_yubikey_aws=$(gum confirm "Do you want to configure your YubiKey for AWS Vault MFA (OATH-TOTP)?" --affirmative "Yes" --negative "No" --default=false && echo "true" || echo "false")

if [[ $setup_yubikey_aws == "true" ]]; then

    # Check prerequisites
    if ! command -v ykman &> /dev/null; then
        status "ykman (yubikey-manager) is not installed. Please run the essential apps installer first."
        return 1
    fi

    if ! command -v aws-vault &> /dev/null; then
        status "aws-vault is not installed. Please run the essential apps installer first."
        return 1
    fi

    # Verify YubiKey is connected and OATH is available
    if ! ykman info &> /dev/null; then
        status "No YubiKey detected. Please insert your YubiKey and try again."
        return 1
    fi

    if ! ykman oath info &> /dev/null; then
        status "OATH is not available on your YubiKey. Please check your YubiKey model."
        return 1
    fi

    status "YubiKey detected with OATH support."

    echo ""
    gum style \
        --border double --border-foreground 208 \
        --padding "1 2" --margin "0 1" \
        "YubiKey OATH-TOTP setup for AWS Vault" \
        "" \
        "This will configure your YubiKey to generate TOTP codes" \
        "for AWS MFA, so you can use aws-vault with a touch instead" \
        "of typing a 6-digit code." \
        "" \
        "AWS CLI does NOT support FIDO-U2F, only TOTP." \
        "Your YubiKey's OATH-TOTP feature bridges this gap."
    echo ""

    # List existing OATH accounts on the YubiKey
    existing_accounts=$(ykman oath accounts list 2>/dev/null)
    if [ -n "$existing_accounts" ]; then
        echo "Existing OATH accounts on your YubiKey:"
        echo "$existing_accounts"
        echo ""
    fi

    # Step 1: Collect AWS account information
    echo "━━━ Step 1: Create a new Virtual MFA device in AWS ━━━"
    echo ""
    echo "You likely already have a Virtual MFA device for your authenticator app."
    echo "You need to create a SECOND Virtual MFA device specifically for your YubiKey."
    echo "AWS supports multiple MFA devices per user — they can coexist."
    echo ""
    echo "  1. Go to AWS Console → IAM → Users → Your user"
    echo "  2. In the Summary section, copy your User ARN"
    echo "     (e.g. arn:aws:iam::123456789012:user/your.username)"
    echo "  3. Go to the Security credentials tab"
    echo "  4. Under MFA, click 'Assign MFA device'"
    echo "  5. Give it a recognizable name (e.g. 'yubikey')"
    echo "  6. Choose 'Authenticator app' (Virtual MFA device)"
    echo "  7. Click 'Show secret key' and copy it"
    echo "  8. Do NOT close the AWS page yet — you'll need it to enter two codes"
    echo ""

    user_arn=$(gum input --prompt "Enter your User ARN (from step 2): " --placeholder "arn:aws:iam::123456789012:user/your.username")

    if [ -z "$user_arn" ]; then
        status "No User ARN provided. Aborting."
        return 1
    fi

    if ! [[ "$user_arn" =~ ^arn:aws:iam::[0-9]+:user/.+$ ]]; then
        status "Invalid User ARN format. Expected: arn:aws:iam::<account-id>:user/<username>"
        return 1
    fi

    # Extract account ID from user ARN
    aws_account_id=$(echo "$user_arn" | cut -d: -f5)

    mfa_device_name=$(gum input --prompt "Enter the MFA device name (from step 5): " --placeholder "yubikey")

    if [ -z "$mfa_device_name" ]; then
        status "No device name provided. Aborting."
        return 1
    fi

    mfa_arn="arn:aws:iam::${aws_account_id}:mfa/${mfa_device_name}"
    status "MFA ARN: $mfa_arn"

    # Check if this account already exists on the YubiKey
    if echo "$existing_accounts" | grep -q "$mfa_arn"; then
        overwrite=$(gum confirm "An OATH account for '$mfa_arn' already exists on your YubiKey. Do you want to replace it?" --affirmative "Yes, replace" --negative "No, abort" --default=false && echo "true" || echo "false")
        if [[ $overwrite == "true" ]]; then
            status "Removing existing OATH account..."
            ykman oath accounts delete "$mfa_arn" --force
        else
            status "Aborting. Existing account unchanged."
            return 0
        fi
    fi

    # Step 2: Add the TOTP secret to the YubiKey
    echo ""
    echo "━━━ Step 2: Store TOTP secret on YubiKey ━━━"
    echo ""
    echo "Enter the base32 secret key from the AWS console."
    echo "This is the key shown when you click 'Show secret key' during MFA setup."
    echo ""

    secret_key=$(gum input --prompt "Enter the base32 secret key: " --password)

    if [ -z "$secret_key" ]; then
        status "No secret key provided. Aborting."
        return 1
    fi

    # Remove any spaces or formatting from the secret
    secret_key=$(echo "$secret_key" | tr -d ' ')

    status "Adding OATH-TOTP account to YubiKey (touch required for code generation)..."
    if ! ykman oath accounts add -t "$mfa_arn" "$secret_key"; then
        status "Failed to add OATH account to YubiKey."
        return 1
    fi

    status "OATH-TOTP account added to YubiKey successfully."

    # Step 3: Activate the MFA device in AWS
    echo ""
    echo "━━━ Step 3: Activate MFA device in AWS ━━━"
    echo ""
    echo "You need to enter two consecutive TOTP codes in the AWS console to activate the device."
    echo "Touch your YubiKey when prompted to generate each code."
    echo ""

    echo "Generating first code (touch your YubiKey)..."
    code1=$(ykman oath accounts code --single "$mfa_arn")
    if [ $? -ne 0 ]; then
        status "Failed to generate TOTP code. Please check your YubiKey."
        return 1
    fi
    echo "  Code 1: $code1"

    echo ""
    echo "Waiting 30 seconds for the next TOTP window..."
    for i in $(seq 30 -1 1); do
        printf "\r  %2d seconds remaining..." "$i"
        sleep 1
    done
    echo ""
    echo ""

    echo "Generating second code (touch your YubiKey)..."
    code2=$(ykman oath accounts code --single "$mfa_arn")
    if [ $? -ne 0 ]; then
        status "Failed to generate second TOTP code."
        return 1
    fi
    echo "  Code 2: $code2"

    echo ""
    echo "Enter these two codes in the AWS console to activate your MFA device:"
    echo "  Code 1: $code1"
    echo "  Code 2: $code2"
    echo ""

    gum confirm "Have you entered both codes in the AWS console and activated the device?" || {
        status "Please complete the activation in the AWS console before proceeding."
        echo "You can always re-run this script to configure aws-vault later."
        return 0
    }

    # Step 4: Configure aws-vault
    echo ""
    echo "━━━ Step 4: Configure AWS profiles ━━━"
    echo ""

    configure_aws=$(gum confirm "Do you want to automatically add mfa_serial and mfa_process to your AWS config profiles?" --affirmative "Yes" --negative "No, I'll do it manually" --default=true && echo "true" || echo "false")

    if [[ $configure_aws == "true" ]]; then
        aws_config="$HOME/.aws/config"

        if [ ! -f "$aws_config" ]; then
            status "No ~/.aws/config found. Creating one."
            mkdir -p "$HOME/.aws"
            touch "$aws_config"
        fi

        # Parse existing profiles from config
        profiles=$(grep -oP '(?<=\[profile\s)[^\]]+' "$aws_config" 2>/dev/null || true)

        if [ -z "$profiles" ]; then
            status "No profiles found in ~/.aws/config. Please add profiles manually."
        else
            echo "Found profiles in ~/.aws/config:"
            echo "$profiles"
            echo ""

            selected_profiles=$(echo "$profiles" | gum choose --no-limit --header "Select profiles to configure with YubiKey MFA (space to select, enter to confirm):")

            if [ -n "$selected_profiles" ]; then
                while IFS= read -r profile; do
                    status "Configuring profile: $profile"

                    # Check if mfa_serial already exists for this profile
                    # We need to update the section for this profile
                    profile_section_start=$(grep -n "^\[profile $profile\]" "$aws_config" | cut -d: -f1)

                    if [ -z "$profile_section_start" ]; then
                        status "Could not find profile section for '$profile'. Skipping."
                        continue
                    fi

                    # Find the end of this profile section (next [profile] or [default] or EOF)
                    next_section=$(tail -n +$((profile_section_start + 1)) "$aws_config" | grep -n '^\[' | head -1 | cut -d: -f1)
                    if [ -n "$next_section" ]; then
                        profile_section_end=$((profile_section_start + next_section - 1))
                    else
                        profile_section_end=$(wc -l < "$aws_config")
                    fi

                    # Remove any existing mfa_serial and mfa_process lines in this section
                    sed -i "${profile_section_start},${profile_section_end} {/^mfa_serial\s*=/d; /^mfa_process\s*=/d}" "$aws_config"

                    # Re-read the profile section start (line numbers may have shifted)
                    profile_section_start=$(grep -n "^\[profile $profile\]" "$aws_config" | cut -d: -f1)

                    # Add mfa_serial and mfa_process after the profile header
                    sed -i "${profile_section_start}a\\mfa_serial = ${mfa_arn}\nmfa_process = ykman oath accounts code --single ${mfa_arn}" "$aws_config"

                    status "Profile '$profile' configured."
                done <<< "$selected_profiles"

                echo ""
                status "AWS config updated. Current config:"
                echo ""
                cat "$aws_config"
            else
                status "No profiles selected."
            fi
        fi
    fi

    # Done
    echo ""
    gum style \
        --border double --border-foreground 76 \
        --padding "1 2" --margin "0 1" \
        "✅ YubiKey OATH-TOTP configured for AWS Vault"
    echo ""
    echo "Usage:"
    echo "  aws-vault exec <profile> -- <command>"
    echo ""
    echo "Example:"
    echo "  aws-vault exec acme -- aws s3 ls"
    echo ""
    echo "Your YubiKey will blink — touch it to approve the MFA code."
    echo ""
    echo "If you prefer to not use mfa_process in config, you can also use:"
    echo "  aws-vault exec --prompt ykman <profile> -- <command>"
    echo "  or: export AWS_VAULT_PROMPT=ykman"
    echo ""

    if [ -n "$configure_aws" ] && [[ $configure_aws != "true" ]]; then
        echo "Manual configuration — add this to your profile(s) in ~/.aws/config:"
        echo ""
        echo "  mfa_serial = $mfa_arn"
        echo "  mfa_process = ykman oath accounts code --single $mfa_arn"
        echo ""
    fi
fi
