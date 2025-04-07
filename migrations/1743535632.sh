#!/bin/bash
set -e

# Example migration to test the migration system

status "Checking if yay is installed..."

if ! command -v yay &> /dev/null; then
    status "Yay is not installed, installing it..."
    install_package "yay" aur
fi
