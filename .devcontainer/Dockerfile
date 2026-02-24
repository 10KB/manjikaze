FROM archlinux:base-devel

# Update pacman and install basic tools needed for scripting and development
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm \
    git \
    sudo \
    wget \
    curl \
    jq \
    fd \
    yamllint \
    shellcheck \
    python \
    github-cli \
    alacritty \
    kitty \
    && pacman -Scc --noconfirm

WORKDIR /root
