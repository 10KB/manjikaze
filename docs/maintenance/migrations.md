# Migrations

Manjikaze uses a migration system to manage updates and changes to your environment over time. This document explains how migrations work and how they keep your system consistent.

## What Are Migrations?

Migrations are scripts that automatically apply changes to your system as Manjikaze evolves. They ensure that:

1. Your system gets updated consistently with new features and fixes
2. Configuration changes are applied correctly
3. New dependencies are installed as needed
4. System components are kept in sync with each other

Think of migrations as a way to incrementally upgrade your Manjikaze environment safely and predictably.

## How Migrations Work

The migration system runs automatically when you start Manjikaze. Here's how it works:

1. When you start Manjikaze, and during an [update](updates.md) right after the system packages, it checks for any pending migrations
2. If pending migrations are found, you'll be asked if you want to run them
3. Each migration runs in sequence, with newer migrations only running after older ones complete
4. Each migration runs in a process of its own, so a migration that exits can't stop Manjikaze
5. Successfully completed migrations are recorded in the state file
6. If a migration fails, the process stops to prevent inconsistencies

A new installation records the migrations it came with as done, without running them: its install scripts already include what those migrations change. A migration therefore needs a matching change in the install scripts, so that new installations get it too.

## Running Migrations from the Command Line

- `manjikaze migrate` runs the pending migrations without asking first.
- `manjikaze migrate --pending` prints the pending migrations, one per line, without running them or asking for sudo. It exits with 0 when migrations are pending and with 1 when there are none, so scripts can use it as a check.

Migrations are designed to be idempotent - meaning they can be run multiple times safely without causing issues.

## Migration State Management

Manjikaze keeps track of which migrations have already been applied through a state system. This state is stored in `.manjikaze_state.json`: in your Manjikaze directory for a git install, and in `~/.local/share/manjikaze/` for a [system package install](system-package.md).

Each time a migration runs successfully, it gets recorded in this file with a timestamp indicating when it was applied. This ensures that migrations only run once, even if you restart Manjikaze multiple times.

## Types of Changes in Migrations

Migrations can include various types of changes:

- Installing new packages
- Updating configuration files
- Enabling system services
- Applying security hardening
- Adding new features
- Fixing issues with existing components

## Migration Naming Convention

Migration files are named `<unix timestamp>_<description>.sh`, in lowercase with underscores (e.g., `1773761794_install_git_lfs.sh`). The timestamp makes them run in the order they were created, and the file name without `.sh` is the id recorded in the state file. The checks that run on every pull request enforce this.

## Writing a Migration

1. Create a script in the `migrations/` directory, named as described above
2. Start it with `#!/bin/bash`, followed by `set -e` as its first command
3. Use `status` to report progress, and the helpers from `lib/common.sh` such as `install_package` and `is_installed`. `$MANJIKAZE_DIR` and `$STATE_FILE` are set as well
4. End early with `return 0` when the migration doesn't apply to this system, for example because a feature isn't installed
5. When the change only takes effect after a reboot, call `require_reboot "<reason>"`. The update then offers a reboot with that reason until the system has booted again

Manjikaze sources the migration in a process of its own. Any command that fails, a `return` with a non-zero code or an `exit` with a non-zero code marks the migration as failed, and Manjikaze stops before the next migration. An `exit 0` ends only that migration, which then counts as done.

Migrations should be idempotent and leave changes a user made to their own configuration alone.

## Troubleshooting Migrations

If you encounter issues with migrations:

1. Check the console output for specific error messages
2. Look at the last attempted migration in the logs
3. Fix any issues mentioned in the error message
4. Try running Manjikaze again

If a migration continues to fail, you can:

- Reach out to the community for help
- Manually apply the changes the migration was attempting
- Skip the problematic migration (advanced users only)
