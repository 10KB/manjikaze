# Cursor Installation

## Overview

Manjikaze installs [Cursor](https://cursor.sh/) (an AI-powered code editor) using an extracted AppImage approach rather than the traditional AUR package installation. This document explains the rationale behind this decision and the benefits it provides.

## Installation Method

Instead of installing Cursor using `cursor-bin` from the AUR, Manjikaze:

1. Downloads the latest Cursor AppImage from the official source
2. Extracts the AppImage contents to `~/.local/share/cursor/`
3. Creates a symlink at `~/.local/bin/cursor`
4. Sets up a proper desktop entry for integration with the system

## Benefits

### 1. Improved Terminal Integration

The primary motivation for this approach is to fix issues with [mise-en-place](https://mise.jdx.dev/) integration in Cursor's integrated terminal. When Cursor runs inside an AppImage sandbox, it has limited access to the host environment, which can break tools like mise that rely on PATH extensions and shell integration.

By extracting the AppImage, Cursor runs directly on the host system without these sandbox limitations, allowing the integrated terminal to properly access and use mise-managed tools and environments.

### 2. Better Update Management

This approach also allows Manjikaze to:

- Detect the installed Cursor version more accurately (from its package.json)
- Compare it with the latest available version
- Provide seamless updates through the `manjikaze update` command

## Migration

If you previously installed Cursor through the AUR, Manjikaze provides a migration script to convert your installation to this optimized approach. The migration:

1. Removes the AUR package
2. Downloads and extracts the latest AppImage
3. Sets up the proper desktop integration

**Note:** This migration may result in the loss of some Cursor settings and chat history, as they're stored in different locations between installation methods.

## Update

The best approach to update Cursor is to use the `manjikaze update` command. This will update all installed applications, including Cursor. If you manually want to update Cursor ony, you can run the following:

```bash
cd ~/.manjikaze
source lib/common.sh
source app/installations/essential/cursor.sh
install_cursor
```
