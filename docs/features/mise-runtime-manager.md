# Mise Runtime Manager

Manjikaze includes [mise](https://mise.jdx.dev/), a runtime version manager that replaces tools like asdf, nvm, pyenv, rbenv, etc.

## What is mise?

Mise is a single tool that manages multiple programming language runtimes and tooling. It's compatible with asdf plugins and has features to manage environment variables per project.

## Default Configuration

Manjikaze configures mise with these defaults:

- Node.js LTS
- Python (latest version)
- Yarn package manager
- Pipx for isolated Python applications

## Basic Usage

### Installing a Runtime

```bash
# Install the latest version
mise install python

# Install a specific version
mise install node@18.16.0

# Install latest in a major version
mise install node@18
```

### Setting Global Defaults

```bash
# Set global default version
mise use --global node@lts
mise use --global python@latest
```

### Project-specific Versions

```bash
# Create a .mise.toml in your project directory
mise use node@18
mise use python@3.11
```

### Executing Commands

```bash
# Run a command with the configured runtime
mise exec -- npm install
mise exec -- python --version

# Short form
mise x -- npm install
```

### Listing Installed Versions

```bash
# Show all installed tools
mise ls

# Show available versions for a tool
mise ls-remote node
```

## Configuration Files

Mise uses several configuration methods:

1. **Global config**: `~/.config/mise/config.toml`
2. **Project config**: `.mise.toml` in project directory
3. **Compatible files**: `.node-version`, `.python-version`, etc.

Example .mise.toml:

```toml
[tools]
node = "18"
python = "3.11"

[env]
NODE_ENV = "development"
```

## Learn More

For complete documentation, visit:

- [Mise Official Documentation](https://mise.jdx.dev/)
- [GitHub Repository](https://github.com/jdx/mise)

---

[← GUIs](gui.md) | [AWS Tools →](aws-tools.md)