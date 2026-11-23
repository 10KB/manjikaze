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

#### Git Worktrees

A worktree is a second checkout of the same repository, on another branch, so you can work on several branches at once, for example with an agent in each. Manjikaze adds these commands:

| Command        | What it does                                                                                                   |
| -------------- | -------------------------------------------------------------------------------------------------------------- |
| `wt`           | A menu to check out a worktree's branch, or to go to, create or remove a worktree                              |
| `wt <branch>`  | Makes the branch the active one of the main checkout. If the branch has a worktree, that worktree is removed |
| `wta <branch>` | Creates a worktree for the branch at `../<repository>--<branch>` and goes there                                |
| `wtd`          | Removes the worktree you are in and its branch, after asking, and goes back to the main checkout               |

A typical flow: agents work on several tasks at once, each in a worktree of its own. When one is done, `wt <branch>` (or **Check out a worktree's branch** in the menu) checks its branch out in the main checkout and removes the worktree. A dev server that runs from the main checkout picks up the files, and you go on in that branch.

- **Check out a worktree's branch** lists the worktrees with a branch. Changes in the worktree that aren't committed come along after you confirm. It stops when the main checkout has changes that aren't committed.
- **Go to a worktree** lists the other worktrees by their branch, the main checkout included.
- **New worktree** lists the branches that don't have a worktree yet, also those that are only on `origin`. Type a name that doesn't exist to create a new branch from the current commit.
- **Remove a worktree** lists every worktree except the main checkout. If you are in the one you remove, you end up in the main checkout.
- A worktree goes to `../<repository>--<branch>`, and a `/` in the branch name becomes `-` in the directory name.
- Changes that aren't committed, and commits that aren't merged, are only thrown away when you confirm that separately. A branch that was squash-merged on GitHub and deleted there counts as not merged, so you are asked.
- In a new worktree, mise asks again before it trusts the project's `mise.toml`.
- An agent session, such as Claude Code, locks the worktree it works in. Before `wt` checks out its branch or removes it, it shows the lock reason and asks whether to unlock it. The process in the reason may run in a devcontainer, so `wt` can't check whether the session is still running.
- A worktree that an agent made in a devcontainer is registered with its path in the container, such as `/usr/src/app/.claude/worktrees/<name>`. `wt` finds it in the repository here, and can check out its branch or remove it. Before it does, it points the worktree's links to the paths here, so git can no longer use that worktree in the devcontainer. **Go to a worktree** goes there without changing it, but git only works in it inside the devcontainer.

The git plugin's own `gwt` aliases (`gwta`, `gwtls`, `gwtrm`) remain available for plain `git worktree` commands.

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

### Ncdu

[Ncdu](https://dev.yorhel.nl/ncdu) is an ncurses disk usage analyzer for finding what is consuming space on your filesystem. Run `ncdu` in a directory or pass a path (for example `ncdu /home`). Navigate with the arrow keys, enter a directory to scan it, and press `d` to delete a selected item (use with care).

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

## Herdr Agent Workspace

The optional `herdr` app sets up [Herdr](https://herdr.dev) to run several coding agents in parallel, with the agents inside your devcontainers and access from your phone. It installs:

-   **Herdr**, Bun and the devcontainer CLI through mise
-   **[vscode-devcontainers-herdr](https://github.com/scott-the-programmer/vscode-devcontainers-herdr)** to run agents inside a devcontainer while Herdr tracks their state
-   **[Ovis](https://github.com/devswha/ovis)**, a browser and phone client for Herdr, with telemetry disabled
-   **Tailscale**, with Ovis served on your tailnet over HTTPS and optional Tailscale SSH

Both plugins are pinned to a release in the install script. Herdr does not sandbox plugins; they run as your user.

On native Docker the devcontainer relay needs the Herdr control socket on the `docker0` bridge. Every container on that bridge can then control Herdr without authentication, so the installer asks before enabling it.

Daily use:

```bash
devcontainer up --workspace-folder .
herdr          # then run `hdc` in a pane to start Claude Code in the container
```

`Super + Ctrl + Return` opens Alacritty attached to your Herdr session.

| Alias | Action |
|-------|--------|
| `hdc` | Start Claude Code in the devcontainer, tracked by Herdr |
| `hdx` | Start Codex in the devcontainer, tracked by Herdr |
| `hds` | Start a shell in the devcontainer and track the Claude Code you start from it |
| `dcsh` | Open a shell in the devcontainer of the current repository, for example to run a dev server |

Detach with `ctrl+b q`; agents keep running. On your phone, install Tailscale, open the address from `tailscale serve status` and add it to your home screen.

## Customizing Your Shell

You can customize your shell environment by editing the following files:

-   `~/.zshrc` - Main Zsh configuration file
-   `~/.oh-my-zsh/custom/` - Directory for custom plugins and themes

Manjikaze keeps its own shell functions, such as `wt`, in `~/.oh-my-zsh/custom/manjikaze.zsh` and replaces that file when it changes. Put your own settings in `~/.zshrc` or in another file in that directory.

To add new Oh My Zsh plugins, edit the plugins line in your `.zshrc` file:

```bash
plugins=(archlinux aws docker docker-compose git git-flow zoxide your-new-plugin)
```

Then reload your configuration with `source ~/.zshrc`.
