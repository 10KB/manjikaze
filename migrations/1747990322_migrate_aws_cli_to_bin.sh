#!/bin/bash
set -e

status "Migrating AWS CLI from aws-cli-v2 to aws-cli-bin..."

# Check if aws-cli-v2 is installed
if pacman -Q "aws-cli-v2" &>/dev/null; then
    status "Found aws-cli-v2 package, migrating to aws-cli-bin..."

    uninstall_package "aws-cli-v2" aur

    status "AWS CLI migration completed successfully!"
fi

source "$MANJIKAZE_DIR/app/installations/essential/aws-cli.sh"