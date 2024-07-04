#!/bin/bash

### Configuration ###

# Git config
# TODO: Copy over from dotfiles
if [[ ! -f "$HOME/.gitconfig" ]]; then
    git config --global credential.helper store
    git config --global http.postBuffer 157286400
    git config --global pack.window 1
    git config --global user.email "garret.patten@proton.me"
    git config --global user.name "Garret Patten"
    git config --global pull.rebase false
fi

### Runtimes ###

# Node.js && npm
if [[ ! -f "/usr/bin/node" ]]; then
    sudo dnf module install nodejs:18/common -y
fi

# Python & pip
if [[ ! -f "/usr/bin/python" ]]; then
    sudo dnf install python3 -y
fi

### Frameworks ###

# Vue.js
if [[ ! -f "/usr/local/bin/vue" ]]; then
    sudo npm install -g @vue/cli
fi

### Dev Tools ###

# Docker and Docker-Compose
sudo dnf -y install dnf-plugins-core
sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo dnf install docker-compose -y
docker image pull archlinux
docker image pull ubuntu

# GitHub CLI
if [[ ! -f "/usr/local/bin/gh" ]]; then
    sudo dnf install gh -y
fi

# Postman
if [[ ! -f "/usr/bin/postman" ]]; then
    flatpak install flathub com.getpostman.Postman -y
fi

# Semgrep
if [[ ! -f "$HOME/.local/bin/semgrep" ]]; then
    python3 -m pip install semgrep
fi

# Shellcheck
sudo dnf install Shellcheck -y

# Sourcegraph
if [[ ! -f "/usr/local/bin/src" ]]; then
    curl -L https://sourcegraph.com/.api/src-cli/src_linux_amd64 -o "/usr/local/bin/src"
    chmod +x "/usr/local/bin/src"
fi
