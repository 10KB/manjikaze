# Manjikaze

A standardized, secure development environment for Manjaro Linux that can be set up with a single command. Manjikaze automates the installation and configuration of development tools, security measures, and system preferences to create a consistent and efficient workspace for developers.

## Origin and Context

At [10KB](https://10kb.nl), we've used various development environments over the years - from Windows with WSL to native Ubuntu. As our team grew, this diversity began presenting challenges in consistency, security, and knowledge sharing. After careful evaluation, we chose Manjaro Linux as our standard platform, appreciating its rolling release model and extensive package availability through `pacman` and AUR.

Manjikaze emerged from our need to:

- Standardize development environments across our team
- Implement consistent security measures aligned with ISO27001
- Reduce setup time for new team members
- Share optimizations and best practices efficiently

## What's Included

- Interactive setup using Gum TUI
- Security hardening with Yubikey integration
- Automated development environment configuration
- Consistent theming and UI preferences
- Curated selection of development tools
- Standardized package management

## Quick Start

On a fresh Manjaro installation:

```bash
curl -s https://raw.githubusercontent.com/10kb/manjikaze/main/install.sh | bash
```

## Documentation

Our documentation is available in the [docs](docs/README.md) directory.

## License

Manjikaze is released under the MIT License.
