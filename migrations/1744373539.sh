#!/bin/bash
set -e

# Migration script to install and configure UFW (Uncomplicated Firewall)
# This sets up a basic firewall with safe defaults

status "Checking if UFW is installed..."

if ! command -v ufw &> /dev/null; then
    status "UFW is not installed, installing it..."
    install_package "ufw" repo
fi

status "Configuring UFW with safe defaults..."

# Reset any existing rules
sudo ufw --force reset

# Set default policies (deny incoming, allow outgoing)
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Enable UFW
status "Enabling UFW..."
sudo ufw --force enable

status "UFW has been configured and enabled with safe defaults"
status "Current UFW status:"
sudo ufw status verbose
