# Rootless Docker

Manjikaze runs Docker rootless: the Docker daemon runs as your own user instead of as root.

## Why

The usual setup adds you to the `docker` group. That group can reach the root daemon's socket, and anyone who can do that can start a container that mounts `/` and so has root on the machine, without a password. That also bypasses a [YubiKey on sudo](yubikey.md). A process inside a rootless container is at most your own user on the host.

## How It Is Set Up

- `docker-rootless-extras` provides the daemon, which systemd starts for your user when something connects to `$XDG_RUNTIME_DIR/docker.sock`.
- The docker context `rootless` is the default, so `docker`, Docker Compose, devcontainers and VS Code all use the rootless daemon.
- Manjikaze doesn't set `DOCKER_HOST` for the desktop session. That would send every program to one socket, including programs that otherwise check which user's daemon a container belongs to. A program that only reads `DOCKER_HOST` can get it in the shell you start it from.
- Logs are limited to 5 files of 10 MB per container, in `~/.config/docker/daemon.json`. The rootless daemon doesn't read `/etc/docker/daemon.json`.
- You are not in the `docker` group, and the root daemon (`docker.service` and `docker.socket`) is off.

Workstations that used the root daemon are switched by a migration. It sets up rootless Docker first, and only then stops the root daemon and removes you from the `docker` group, which takes effect when you log in again.

## Earlier Containers and Volumes

The root daemon's images, containers and volumes stay in `/var/lib/docker`. Rootless Docker keeps its own in `~/.local/share/docker`. To reach the old ones:

```bash
sudo systemctl start docker
sudo docker volume ls
sudo systemctl stop docker.socket docker.service
```

## Differences from the Root Daemon

- A container can't publish a port below 1024 on the host, unless you lower `net.ipv4.ip_unprivileged_port_start`.
- `--network host` shares the network of the rootless daemon, not of your machine.
- The daemon stops when you log out, and with it your containers.
