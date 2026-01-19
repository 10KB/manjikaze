# Shell Tools

Manjikaze includes a variety of shell tools and utilities to enhance your command-line productivity.

## Zsh and Oh My Zsh

Manjikaze uses Zsh as the default shell, enhanced with the Oh My Zsh framework to provide a rich command-line experience.

### Oh My Zsh Theme

Manjikaze uses the Agnoster theme, which provides:

-   Git status information directly in your prompt
-   Visual indicators for command success/failure
-   Directory path with intelligent truncation
-   Special symbols for superuser and virtual environment status

### Enabled Oh My Zsh Plugins

Manjikaze comes with several useful Oh My Zsh plugins pre-configured:

| Plugin                                                                                    | Description                                                             |
| ----------------------------------------------------------------------------------------- | ----------------------------------------------------------------------- |
| [`archlinux`](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/archlinux)           | Provides aliases for common Arch Linux commands like package management |
| [`aws`](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/aws)                       | AWS CLI completion and prompt integration                               |
| [`docker`](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/docker)                 | Docker command completion and shortcuts                                 |
| [`docker-compose`](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/docker-compose) | Completion and shortcuts for Docker Compose                             |
| [`git`](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/git)                       | Comprehensive Git aliases and functions                                 |
| [`git-flow`](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/git-flow)             | Completion and shortcuts for Git Flow workflow                          |
| [`zoxide`](https://github.com/ajeetdsouza/zoxide)                                         | Smarter directory navigation that learns your habits                    |

#### Docker Compose Plugin

The Docker Compose plugin provides helpful aliases to streamline your workflow:

| Alias    | Command                | Description                      |
| -------- | ---------------------- | -------------------------------- |
| `dco`    | `docker-compose`       | Docker Compose shorthand         |
| `dcb`    | `docker-compose build` | Build containers                 |
| `dce`    | `docker-compose exec`  | Execute command in a container   |
| `dcps`   | `docker-compose ps`    | List containers                  |
| `dcr`    | `docker-compose run`   | Run a command in a new container |
| `dcup`   | `docker-compose up`    | Create and start containers      |
| `dcdown` | `docker-compose down`  | Stop and remove containers       |
| `dcl`    | `docker-compose logs`  | View output from containers      |

For a complete list, run `alias | grep docker-compose` in your terminal.

#### Git Plugin

The git plugin provides many helpful aliases for common Git operations:

| Alias | Command        | Description                      |
| ----- | -------------- | -------------------------------- |
| `g`   | `git`          | Shorthand for git                |
| `gst` | `git status`   | Check repository status          |
| `ga`  | `git add`      | Stage files                      |
| `gc`  | `git commit`   | Commit changes                   |
| `gp`  | `git push`     | Push to remote                   |
| `gl`  | `git pull`     | Pull from remote                 |
| `gco` | `git checkout` | Switch branches or restore files |
| `gd`  | `git diff`     | Show changes                     |

For a complete list of Git aliases, run `alias | grep git` in your terminal.

## Modern CLI Tools

Manjikaze includes several modern replacements for traditional Unix tools to enhance your command-line experience:

### Zoxide

[Zoxide](https://github.com/ajeetdsouza/zoxide) is a smarter alternative to the `cd` command that tracks your most used directories. After visiting a directory once, you can jump to it from anywhere by typing part of its name:

```bash
# First visit a directory normally
cd ~/Projects/manjikaze/documentation

# Later, jump to it from anywhere with just
z manjikaze
```

The more you use a directory, the higher priority it gets in zoxide's ranking.

### Bat

[Bat](https://github.com/sharkdp/bat) is a modern replacement for `cat` with syntax highlighting, line numbers, Git integration, and more:

```bash
# View a file with syntax highlighting
bat config.yaml

# Use as a colorizing pager for other commands
git show | bat
```

### Fd

[Fd](https://github.com/sharkdp/fd) is a simple, fast, and user-friendly alternative to the `find` command:

```bash
# Find all markdown files in current directory
fd .md

# Find all files containing "config" in name
fd config
```

### Btop

[Btop](https://github.com/aristocratos/btop) is an advanced system monitor that shows CPU, memory, disk, and network usage in a visually appealing interface. Launch it by typing `btop` in your terminal.

### SSHS

[SSHS](https://github.com/quantumsheep/sshs) is an SSH connection manager that helps you organize and connect to your SSH servers quickly. Run `sshs` to see a list of available connections.

### SVGO

[SVGO](https://github.com/svg/svgo) is a tool for optimizing SVG files. Use it to reduce the size of your SVG files before deployment:

```bash
# Optimize a single SVG file
svgo icon.svg

# Optimize all SVGs in a directory
svgo -f ./icons/
```

### OpenVPN 3

[OpenVPN 3](https://codeberg.org/OpenVPN/openvpn3-linux) is an OpenVPN platform that provides a VPN client. You can manage your VPN connections using simple commands:

```bash
# Load a config file
openvpn3 config-import --config ${client.ovpn}

# Start a VPN session
openvpn3 session-start --config ${client.ovpn}
```

Or read the full tutorial [here](https://openvpn.net/as-docs/tutorials/tutorial--connect-with-linux.html)

## AWS Tools

Manjikaze includes tools for working with AWS:

-   **AWS CLI** - Command-line interface for interacting with AWS services
-   **AWS Vault** - Tool for securely storing and accessing AWS credentials

Detailed documentation for AWS tools is available in the [AWS-specific documentation](aws-tools.md).

## Azure Tools

Manjikaze optionally includes the Azure CLI and Azure Kubelogin for working with Azure and AKS (Azure Kubernetes Service).

## Customizing Your Shell

You can customize your shell environment by editing the following files:

-   `~/.zshrc` - Main Zsh configuration file
-   `~/.oh-my-zsh/custom/` - Directory for custom plugins and themes

To add new Oh My Zsh plugins, edit the plugins line in your `.zshrc` file:

```bash
plugins=(archlinux aws docker docker-compose git git-flow zoxide your-new-plugin)
```

Then reload your configuration with `source ~/.zshrc`.
