#!/bin/bash
set -e

status "Checking if pamtester is installed..."

if ! command -v pamtester &> /dev/null; then
    status "pamtester is not installed, installing it..."
    install_package "pamtester" aur
fi

