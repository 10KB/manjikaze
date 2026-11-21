#!/bin/bash
set -e

# Machine policies for Chrome, Chromium, Brave and Firefox: no usage statistics or visited URLs to
# Google, Brave or Mozilla, no promotions, and the Bitwarden extension in every profile.

source "$MANJIKAZE_DIR/app/security/browser/browser-policies.sh"
# The last command decides whether the migration counts as done, so a failure is retried.
apply_browser_policies
