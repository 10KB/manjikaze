#!/bin/bash
set -e

# An update through pamac or 42kb brings migrations without running them. A notice after login now
# says when migrations are waiting, with a button that applies them.

source "$MANJIKAZE_DIR/app/security/updates/migration-notice.sh"
install_migration_notice
