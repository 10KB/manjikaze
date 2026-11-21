#!/bin/bash

source "$MANJIKAZE_DIR/app/security/browser/browser-policies.sh"

if apply_browser_policies; then
    status "chrome://policy, brave://policy and about:policies show the active policies."
else
    status "The browser policies were not fully applied. Fix the error above and choose this option again."
fi
