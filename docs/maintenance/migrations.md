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

1. When you start Manjikaze, it checks for any pending migrations
2. If pending migrations are found, you'll be asked if you want to run them
3. Each migration runs in sequence, with newer migrations only running after older ones complete
4. Successfully completed migrations are recorded in the state file
5. If a migration fails, the process stops to prevent inconsistencies

Migrations are designed to be idempotent - meaning they can be run multiple times safely without causing issues.

## Migration State Management

Manjikaze keeps track of which migrations have already been applied through a state system. This state is stored in the `.manjikaze_state.json` file in your Manjikaze directory.

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

Migration files are named using a timestamp format (e.g., `1743535632.sh`), which ensures they run in the correct chronological order. The timestamp indicates when the migration was created, not when it should be run.

## Adding Custom Migrations

Advanced users can create their own migrations to customize Manjikaze further. To create a custom migration:

1. Create a new script in the `migrations/` directory with a name in timestamp format
2. Make your script executable (`chmod +x`)
3. Add the necessary commands to make your desired changes
4. Use the `status` function to report progress
5. Ensure proper error handling with appropriate exit codes

Remember that custom migrations should follow the same principles as built-in ones - they should be idempotent, handle errors gracefully, and exit with appropriate status codes.

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
